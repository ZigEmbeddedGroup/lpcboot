const std = @import("std");

const serial = @import("serial");
const uuencode = @import("uuencode");

pub const Isp = struct {
    const Self = @This();

    port: std.fs.File,

    pub fn open(path: []const u8) !Self {
        var serial_port = try std.fs.cwd().openFile(path, .{ .mode = .read_write });
        errdefer serial_port.close();

        try serial.configureSerialPort(serial_port, .{
            .baud_rate = 115_200,
            .parity = .none,
            .stop_bits = .one,
            .word_size = 8,
            .handshake = .none,
        });

        return Self{
            .port = serial_port,
        };
    }

    pub fn close(self: *Self) void {
        serial.changeControlPins(self.port, .{
            .dtr = false,
            .rts = false,
        }) catch std.log.err("failed to raise both pins", .{});

        self.port.close();
        self.* = undefined;
    }

    pub const ResetTarget = enum { application, bootloader };
    pub fn resetDevice(self: Self, target: ResetTarget) !void {
        // dtr low = no reset
        // dtr high = reset

        // rts low = application code
        // rts high = bootloader code

        try serial.changeControlPins(self.port, .{
            .dtr = true, // reset pin
            .rts = true,
        });

        std.time.sleep(25 * std.time.ns_per_ms);

        // prevent a race condition here:
        // first make sure we have the RTS lane set up properly,
        // then release the reset pin.
        // This prevents the racy condition that we release reset before
        // we actually selected to bootloader

        const app_select = (target == .bootloader);
        try serial.changeControlPins(self.port, .{ .rts = app_select });
        try serial.changeControlPins(self.port, .{ .dtr = false });

        std.time.sleep(25 * std.time.ns_per_ms);

        try serial.flushSerialPort(self.port, true, true);
    }

    const HandshakeOptions = struct { freq: u32 = 0 };
    pub fn performHandshake(self: Self, options: HandshakeOptions) !void {
        const writer = self.port.writer();
        const reader = self.port.reader();

        sync_loop: while (true) {
            try writer.writeByte('?');

            const c = try reader.readByte();

            if (c == 'S') {
                const expected = "Synchronized\r\n";

                std.log.info("performing handshake...", .{});

                var input: [expected.len]u8 = undefined;
                input[0] = c;
                try reader.readNoEof(input[1..]);

                if (std.mem.eql(u8, &input, expected)) {
                    try writer.writeAll(expected);
                    std.log.info("handshake done.", .{});
                    break :sync_loop;
                }
                std.log.err("failed to handshake", .{});
                return error.HandshakeFailed;
            } else {
                std.log.info("unexpected sync: {c}", .{c});
            }
        }
        // device is echoing while handshaking, so we have to expected "request\r\nanswer\r\n"
        try self.expectLine("Synchronized\x0DOK");

        var buffer: [64]u8 = undefined;
        const fmt = try std.fmt.bufPrint(&buffer, "{d}\r\n", .{options.freq});
        try writer.writeAll(fmt);

        const response = try std.fmt.bufPrint(&buffer, "{d}\rOK", .{options.freq});
        try self.expectLine(response);

        // Turn echo off
        try writer.writeAll("A 0\r\n");
        try self.expectLine("A 0\r0");
    }

    pub fn unlock(self: Self) !void {
        try self.exec(.unlock, &.{"23130"});
    }
    pub fn setBaudRate(self: Self) !void {
        _ = self;
    }
    // pub fn echo(self: Self) !void {
    //     _ = self;
    // }

    /// Writes data into the chip ram.
    /// - `offset` is the base address the data will go. Must be aligned to 4.
    /// - `buffer` the data to write. Length must be a multiple of 4.
    pub fn writeToRam(self: Self, offset: u32, buffer: []const u8) !void {
        std.debug.assert(std.mem.isAligned(offset, 4));
        std.debug.assert(std.mem.isAligned(buffer.len, 4));

        var len_buf: [16]u8 = undefined;
        var off_buf: [16]u8 = undefined;

        const len_digits = std.fmt.bufPrint(&len_buf, "{d}", .{buffer.len}) catch unreachable;
        const off_digits = std.fmt.bufPrint(&off_buf, "{d}", .{offset}) catch unreachable;

        try self.exec(.write_to_ram, &.{ off_digits, len_digits });

        const writer = self.port.writer();

        var i: usize = 0;
        var lines: u32 = 0;
        var calc_checksum: u32 = 0;
        var checksum_offset: usize = 0;
        while (i < buffer.len) {
            const transmit_len = std.math.min(45, buffer.len - i);
            const segment = buffer[i .. i + transmit_len];

            try uuencode.encodeLine(writer, segment);
            try writer.writeAll("\r\n");
            i += segment.len;

            lines += 1;
            for (segment) |c| {
                calc_checksum += c;
            }

            if (lines >= 20 or i >= buffer.len) {
                defer {
                    lines = 0;
                    calc_checksum = 0;
                }

                try writer.print("{d}\r\n", .{calc_checksum});

                var cs_buffer: [64]u8 = undefined;
                const checksum_request = try self.fetchLine(&cs_buffer);

                if (std.mem.eql(u8, checksum_request, "OK")) {
                    checksum_offset = i;
                } else if (std.mem.eql(u8, checksum_request, "RESEND")) {
                    i = checksum_offset;
                } else {
                    return error.UnexpectedData;
                }
            }
        }
    }

    /// Reads data from the chip memory.
    /// - `offset` is the base address the data will be read from. Must be aligned to 4.
    /// - `buffer` the data to read. Length must be a multiple of 4.
    pub fn readMemory(self: Self, offset: u32, buffer: []u8) !void {
        std.debug.assert(std.mem.isAligned(offset, 4));
        std.debug.assert(std.mem.isAligned(buffer.len, 4));

        var len_buf: [16]u8 = undefined;
        var off_buf: [16]u8 = undefined;

        const len_digits = std.fmt.bufPrint(&len_buf, "{d}", .{buffer.len}) catch unreachable;
        const off_digits = std.fmt.bufPrint(&off_buf, "{d}", .{offset}) catch unreachable;

        try self.exec(.read_memory, &.{ off_digits, len_digits });

        var i: usize = 0;
        var lines: u8 = 0;
        var calc_checksum: u32 = 0;
        var checksum_offset: usize = 0;
        while (i < buffer.len) {
            var line_buffer: [45]u8 = undefined;
            const line = try uuencode.decodeLine(self.port.reader(), &line_buffer);

            var rest_buffer: [64]u8 = undefined;
            const rest = try self.fetchLine(&rest_buffer);

            if (rest.len > 0) {
                std.log.warn("received garbage data after uuencoded: {s}", .{rest});
            }

            std.mem.copy(u8, buffer[i..], line);
            i += line.len;

            for (line) |c| {
                calc_checksum += c;
            }

            lines += 1;
            if (lines >= 20 or i >= buffer.len) {
                defer {
                    lines = 0;
                    calc_checksum = 0;
                }

                var checksum_buffer: [64]u8 = undefined;
                const checksum_str = try self.fetchLine(&checksum_buffer);

                const sent_checksum = try std.fmt.parseInt(u32, checksum_str, 10);

                if (sent_checksum != calc_checksum) {
                    std.log.err("checksum mismatch: Expected {d}, received {d}", .{
                        calc_checksum,
                        sent_checksum,
                    });
                    try self.port.writeAll("RESEND\r\n");
                    i = checksum_offset;
                } else {
                    checksum_offset = i;
                    try self.port.writeAll("OK\r\n");
                }
            }
        }
    }

    pub fn prepareSector(self: Self) !void {
        _ = self;
    }

    pub fn copyRamToFlash(self: Self) !void {
        _ = self;
    }

    pub fn go(self: Self, address: u32) !void {
        _ = self;
        _ = address;
    }

    pub fn eraseSector(self: Self) !void {
        _ = self;
    }

    pub fn blankCheckSector(self: Self) !void {
        _ = self;
    }

    pub fn readPartId(self: Self) !PartID {
        try self.exec(.read_part_id, &.{});

        var pid: [64]u8 = undefined;
        const line = try self.fetchLine(&pid);

        const pid_num = std.fmt.parseInt(u32, line, 10) catch return error.UnexpectedData;

        return @intToEnum(PartID, pid_num);
    }

    pub const Version = struct { major: u8, minor: u8 };
    pub fn readBootCodeVersion(self: Self) !Version {
        try self.exec(.read_boot_code_version, &.{});

        var buffer: [64]u8 = undefined;
        const major_string = try self.fetchLine(&buffer);
        const major = std.fmt.parseInt(u8, major_string, 10) catch return error.UnexpectedData;

        const minor_string = try self.fetchLine(&buffer);
        const minor = std.fmt.parseInt(u8, minor_string, 10) catch return error.UnexpectedData;

        return Version{
            .major = major,
            .minor = minor,
        };
    }

    pub fn readSerial(self: Self) ![4]u32 {
        try self.exec(.read_serial, &.{});

        var buffer: [64]u8 = undefined;

        const major_string = try self.fetchLine(&buffer);
        const val0 = std.fmt.parseInt(u32, major_string, 10) catch return error.UnexpectedData;

        const major_string1 = try self.fetchLine(&buffer);
        const val1 = std.fmt.parseInt(u32, major_string1, 10) catch return error.UnexpectedData;

        const major_string2 = try self.fetchLine(&buffer);
        const val2 = std.fmt.parseInt(u32, major_string2, 10) catch return error.UnexpectedData;

        const major_string3 = try self.fetchLine(&buffer);
        const val3 = std.fmt.parseInt(u32, major_string3, 10) catch return error.UnexpectedData;

        return [4]u32{ val0, val1, val2, val3 };
    }

    pub fn compare(self: Self) !void {
        _ = self;
        return error.Unsupported;
    }

    fn exec(self: Self, cmd: Command, args: []const []const u8) !void {
        var writer = self.port.writer();
        try writer.print("{c}", .{@enumToInt(cmd)});
        for (args) |arg| {
            try writer.print(" {s}", .{arg});
        }
        try writer.writeAll("\r\n");

        try self.expectCmdOk();
    }

    fn expectCmdOk(self: Self) (std.fs.File.Reader.Error || Error || error{ EndOfStream, InputTooLarge, UnexpectedData })!void {
        var buffer: [1024]u8 = undefined;

        const ack_string = try self.fetchLine(&buffer);

        const numeric = std.fmt.parseInt(u32, ack_string, 10) catch return error.UnexpectedData;

        const code = std.meta.intToEnum(ErrorCode, numeric) catch return error.UnexpectedData;

        try code.throw();
    }

    fn expectLine(self: Self, expected: []const u8) !void {
        var buffer: [1024]u8 = undefined;

        const ack_string = try self.fetchLine(&buffer);

        if (!std.mem.eql(u8, ack_string, expected)) {
            std.log.warn("unexpected data: {s}", .{
                std.fmt.fmtSliceEscapeUpper(ack_string),
            });
            return error.UnexpectedData;
        }
    }

    fn fetchLine(self: Self, buffer: []u8) ![]u8 {
        var i: usize = 0;
        while (i < buffer.len) {
            const b = try self.port.reader().readByte();
            buffer[i] = b;
            i += 1;
            if (std.mem.endsWith(u8, buffer[0..i], "\r\n")) {
                return buffer[0 .. i - 2];
            }
        }
        return error.InputTooLarge;
    }

    const ErrorCode = enum(u32) {
        success = 0,
        invalid_command = 1,
        src_addr_error = 2,
        dst_addr_error = 3,
        src_addr_not_mapped = 4,
        dst_addr_not_mapped = 5,
        count_error = 6,
        invalid_sector = 7,
        sector_not_blank = 8,
        sector_not_prepared = 9,
        compare_error = 10,
        busy = 11,
        param_error = 12,
        addr_error = 13,
        addr_not_mapped = 14,
        cmd_locked = 15,
        invalid_code = 16,
        invalid_baud_rate = 17,
        invalid_stop_bit = 18,
        code_read_protected = 19,

        pub fn throw(self: @This()) Error!void {
            switch (self) {
                .success => {},
                .invalid_command => return Error.InvalidCommand,
                .src_addr_error => return Error.SrcAddrError,
                .dst_addr_error => return Error.DstAddrError,
                .src_addr_not_mapped => return Error.SrcAddrNotMapped,
                .dst_addr_not_mapped => return Error.DstAddrNotMapped,
                .count_error => return Error.CountError,
                .invalid_sector => return Error.InvalidSector,
                .sector_not_blank => return Error.SectorNotBlank,
                .sector_not_prepared => return Error.SectorNotPrepared,
                .compare_error => return Error.CompareError,
                .busy => return Error.Busy,
                .param_error => return Error.ParamError,
                .addr_error => return Error.AddrError,
                .addr_not_mapped => return Error.AddrNotMapped,
                .cmd_locked => return Error.CmdLocked,
                .invalid_code => return Error.InvalidCode,
                .invalid_baud_rate => return Error.InvalidBaudRate,
                .invalid_stop_bit => return Error.InvalidStopBit,
                .code_read_protected => return Error.CodeReadProtected,
            }
        }
    };

    const Error = error{
        InvalidCommand,
        SrcAddrError,
        DstAddrError,
        SrcAddrNotMapped,
        DstAddrNotMapped,
        CountError,
        InvalidSector,
        SectorNotBlank,
        SectorNotPrepared,
        CompareError,
        Busy,
        ParamError,
        AddrError,
        AddrNotMapped,
        CmdLocked,
        InvalidCode,
        InvalidBaudRate,
        InvalidStopBit,
        CodeReadProtected,
    };

    const Command = enum(u8) {
        unlock = 'U',
        set_baud_rate = 'B',
        echo = 'A',
        write_to_ram = 'W',
        read_memory = 'R',
        prepare_sector = 'P',
        copy_ram_to_flash = 'C',
        go = 'G',
        erase_sector = 'E',
        blank_check_sector = 'I',
        read_part_id = 'J',
        read_boot_code_version = 'K',
        read_serial = 'N',
        compare = 'M',
    };

    pub const PartID = enum(u32) {
        lpc1769 = 638664503, // 0x2611_3F37
        lpc1768 = 637615927, // 0x2601_3F37
        lpc1767 = 637610039, // 0x2601_2837
        lpc1766 = 637615923, // 0x2601_3F33
        lpc1765 = 637613875, // 0x2601_3733
        lpc1764 = 637606178, // 0x2601_1922
        lpc1763 = 637607987, // 0x2601_2033
        lpc1759 = 621885239, // 0x2511_3737
        lpc1758 = 620838711, // 0x2501_3F37
        lpc1756 = 620828451, // 0x2501_1723
        lpc1754 = 620828450, // 0x2501_1722
        lpc1752 = 620761377, // 0x2500_1121
        lpc1751 = 620761368, // 0x2500_1118
        lpc1751_borked = 620761360, // 0x2500_1110
        _,
    };
};