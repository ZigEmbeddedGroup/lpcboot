const std = @import("std");

pub const PartID = enum(u32) {
    _,

    pub fn lookUp(device_id: PartID) ?Device {
        return for (lut) |def| {
            if (@enumToInt(device_id) == def.id)
                break def.device;
        } else null;
    }
};

pub const Device = struct {
    family: DeviceFamily,
    name: []const u8,
    sectors: []const Sector,

    pub fn flashSize(dev: Device) u32 {
        var s: u32 = 0;
        for (dev.sectors) |sect| {
            s += sect.length;
        }
        return s;
    }
};

pub const DeviceFamily = enum {
    lpc111x,
    lpc11Cxx,
    lpc176x,
    lpc175x,
    lpc185x,
    lpc183x,
    lpc182x,
    lpc181x,
};

pub const Sector = struct {
    index: u32,
    offset: u32,
    length: u32,

    fn make(index: u32, size: u32, low: u32, high: u32) Sector {
        const length = high - low + 1;
        std.debug.assert(1024 * size == length);
        return Sector{
            .offset = low,
            .length = length,
            .index = index,
        };
    }
};

const Entry = struct {
    id: u32,
    device: Device,

    fn make(id: u32, family: DeviceFamily, name: []const u8, _sectors: []const Sector) Entry {
        return Entry{
            .id = id,
            .device = Device{
                .family = family,
                .name = name,
                .sectors = _sectors,
            },
        };
    }
};

const lut = [_]Entry{
    // LPC1110:
    Entry.make(0x0A07_102B, .lpc111x, "LPC1110FD20", sectors.lpc1110_4k),
    Entry.make(0x1A07_102B, .lpc111x, "LPC1110FD20", sectors.lpc1110_4k),

    // LPC1111:
    Entry.make(0x0A16_D02B, .lpc111x, "LPC1111FDH20/002", sectors.lpc1111_8k),
    Entry.make(0x1A16_D02B, .lpc111x, "LPC1111FDH20/002", sectors.lpc1111_8k),
    Entry.make(0x041E_502B, .lpc111x, "LPC1111FHN33/101", sectors.lpc1111_8k),
    Entry.make(0x2516_D02B, .lpc111x, "LPC1111FHN33/101", sectors.lpc1111_8k),
    Entry.make(0x2516_D02B, .lpc111x, "LPC1111FHN33/102", sectors.lpc1111_8k),
    Entry.make(0x0416_502B, .lpc111x, "LPC1111FHN33/201", sectors.lpc1111_8k),
    Entry.make(0x2516_902B, .lpc111x, "LPC1111FHN33/201", sectors.lpc1111_8k),
    Entry.make(0x2516_902B, .lpc111x, "LPC1111FHN33/202", sectors.lpc1111_8k),
    Entry.make(0x0001_0013, .lpc111x, "LPC1111FHN33/103", sectors.lpc1111xl_8k),
    Entry.make(0x0001_0012, .lpc111x, "LPC1111FHN33/203", sectors.lpc1111xl_8k),

    // LPC1112:
    Entry.make(0x0A24_902B, .lpc111x, "LPC1112FD20/102", sectors.lpc1112_16k),
    Entry.make(0x1A24_902B, .lpc111x, "LPC1112FD20/102", sectors.lpc1112_16k),
    Entry.make(0x0A24_902B, .lpc111x, "LPC1112FDH20/102", sectors.lpc1112_16k),
    Entry.make(0x1A24_902B, .lpc111x, "LPC1112FDH20/102", sectors.lpc1112_16k),
    Entry.make(0x0A24_902B, .lpc111x, "LPC1112FDH28/102", sectors.lpc1112_16k),
    Entry.make(0x1A24_902B, .lpc111x, "LPC1112FDH28/102", sectors.lpc1112_16k),
    Entry.make(0x042D_502B, .lpc111x, "LPC1112FHN33/101", sectors.lpc1112_16k),
    Entry.make(0x2524_D02B, .lpc111x, "LPC1112FHN33/101", sectors.lpc1112_16k),
    Entry.make(0x2524_D02B, .lpc111x, "LPC1112FHN33/102", sectors.lpc1112_16k),
    Entry.make(0x0425_502B, .lpc111x, "LPC1112FHN33/201", sectors.lpc1112_16k),
    Entry.make(0x2524_902B, .lpc111x, "LPC1112FHN33/201", sectors.lpc1112_16k),
    Entry.make(0x2524_902B, .lpc111x, "LPC1112FHN33/202", sectors.lpc1112_16k),
    Entry.make(0x2524_902B, .lpc111x, "LPC1112FHN24/202", sectors.lpc1112_16k),
    Entry.make(0x2524_902B, .lpc111x, "LPC1112FHI33/202", sectors.lpc1112_16k),
    Entry.make(0x0002_0023, .lpc111x, "LPC1112FHN33/103", sectors.lpc1112xl_16k),
    Entry.make(0x0002_0022, .lpc111x, "LPC1112FHN33/203", sectors.lpc1112xl_16k),
    Entry.make(0x0002_0022, .lpc111x, "LPC1112FHI33/203", sectors.lpc1112xl_16k),

    // LPC1113:
    Entry.make(0x0434_502B, .lpc111x, "LPC1113FHN33/201", sectors.lpc1113_24k),
    Entry.make(0x2532_902B, .lpc111x, "LPC1113FHN33/201", sectors.lpc1113_24k),
    Entry.make(0x2532_902B, .lpc111x, "LPC1113FHN33/202", sectors.lpc1113_24k),
    Entry.make(0x0434_102B, .lpc111x, "LPC1113FHN33/301", sectors.lpc1113_24k),
    Entry.make(0x2532_102B, .lpc111x, "LPC1113FHN33/301", sectors.lpc1113_24k),
    Entry.make(0x2532_102B, .lpc111x, "LPC1113FHN33/302", sectors.lpc1113_24k),
    Entry.make(0x0434_102B, .lpc111x, "LPC1113FBD48/301", sectors.lpc1113_24k),
    Entry.make(0x2532_102B, .lpc111x, "LPC1113FBD48/301", sectors.lpc1113_24k),
    Entry.make(0x2532_102B, .lpc111x, "LPC1113FBD48/302", sectors.lpc1113_24k),
    Entry.make(0x0003_0030, .lpc111x, "LPC1113FBD48/303", sectors.lpc1113xl_24k),
    Entry.make(0x0003_0032, .lpc111x, "LPC1113FHN33/203", sectors.lpc1113xl_24k),
    Entry.make(0x0003_0030, .lpc111x, "LPC1113FHN33/303", sectors.lpc1113xl_24k),

    // LPC1114:
    Entry.make(0x0A40_902B, .lpc111x, "LPC1114FDH28/102", sectors.lpc1114_32k),
    Entry.make(0x1A40_902B, .lpc111x, "LPC1114FDH28/102", sectors.lpc1114_32k),
    Entry.make(0x0A40_902B, .lpc111x, "LPC1114FN28/102", sectors.lpc1114_32k),
    Entry.make(0x1A40_902B, .lpc111x, "LPC1114FN28/102", sectors.lpc1114_32k),
    Entry.make(0x0444_502B, .lpc111x, "LPC1114FHN33/201", sectors.lpc1114_32k),
    Entry.make(0x2540_902B, .lpc111x, "LPC1114FHN33/201", sectors.lpc1114_32k),
    Entry.make(0x2540_902B, .lpc111x, "LPC1114FHN33/202", sectors.lpc1114_32k),
    Entry.make(0x0444_102B, .lpc111x, "LPC1114FHN33/301", sectors.lpc1114_32k),
    Entry.make(0x2540_102B, .lpc111x, "LPC1114FHN33/301", sectors.lpc1114_32k),
    Entry.make(0x2540_102B, .lpc111x, "LPC1114FHN33/302", sectors.lpc1114_32k),
    Entry.make(0x2540_102B, .lpc111x, "LPC1114FHI33/302", sectors.lpc1114_32k),
    Entry.make(0x0444_102B, .lpc111x, "LPC1114FBD48/301", sectors.lpc1114_32k),
    Entry.make(0x2540_102B, .lpc111x, "LPC1114FBD48/301", sectors.lpc1114_32k),
    Entry.make(0x2540_102B, .lpc111x, "LPC1114FBD48/302", sectors.lpc1114_32k),
    Entry.make(0x0004_0040, .lpc111x, "LPC1114FBD48/303", sectors.lpc1114xl_303_32k),
    Entry.make(0x0004_0042, .lpc111x, "LPC1114FHN33/203", sectors.lpc1114xl_203_32k),
    Entry.make(0x0004_0040, .lpc111x, "LPC1114FHN33/303", sectors.lpc1114xl_303_32k),
    Entry.make(0x0004_0060, .lpc111x, "LPC1114FBD48/323", sectors.lpc1114xl_323_48k),
    Entry.make(0x0004_0070, .lpc111x, "LPC1114FBD48/333", sectors.lpc1114xl_333_56k),
    Entry.make(0x0004_0070, .lpc111x, "LPC1114FHN33/333", sectors.lpc1114xl_333_56k),
    Entry.make(0x0004_0040, .lpc111x, "LPC1114FHI33/303", sectors.lpc1114xl_303_32k),
    Entry.make(0x2540_102B, .lpc111x, "LPC11D14FBD100/302", sectors.lpc1114_32k),

    // LPC1115:
    Entry.make(0x0005_0080, .lpc111x, "LPC1115FBD48/303", sectors.lpc1115xl_64k),

    // LPC11Cxx:
    Entry.make(0x1421_102B, .lpc11Cxx, "LPC11C12FBD48/301", sectors.empty),
    Entry.make(0x1440_102B, .lpc11Cxx, "LPC11C14FBD48/301", sectors.empty),
    Entry.make(0x1431_102B, .lpc11Cxx, "LPC11C22FBD48/301", sectors.empty),
    Entry.make(0x1430_102B, .lpc11Cxx, "LPC11C24FBD48/301", sectors.empty),

    // LPC176x:
    Entry.make(0x2611_3F37, .lpc176x, "LPC1769", sectors.lpc17xx_512k),
    Entry.make(0x2601_3F37, .lpc176x, "LPC1768", sectors.lpc17xx_512k),
    Entry.make(0x2601_2837, .lpc176x, "LPC1767", sectors.lpc17xx_512k),
    Entry.make(0x2601_3F33, .lpc176x, "LPC1766", sectors.lpc17xx_256k),
    Entry.make(0x2601_3733, .lpc176x, "LPC1765", sectors.lpc17xx_256k),
    Entry.make(0x2601_1922, .lpc176x, "LPC1764", sectors.lpc17xx_128k),
    Entry.make(0x2601_2033, .lpc176x, "LPC1763", sectors.lpc17xx_256k),

    // LPC175x:
    Entry.make(0x2511_3737, .lpc175x, "LPC1759", sectors.lpc17xx_512k),
    Entry.make(0x2501_3F37, .lpc175x, "LPC1758", sectors.lpc17xx_512k),
    Entry.make(0x2501_1723, .lpc175x, "LPC1756", sectors.lpc17xx_256k),
    Entry.make(0x2501_1722, .lpc175x, "LPC1754", sectors.lpc17xx_128k),
    Entry.make(0x2500_1121, .lpc175x, "LPC1752", sectors.lpc17xx_64k),
    Entry.make(0x2500_1118, .lpc175x, "LPC1751", sectors.lpc17xx_32k),
    Entry.make(0x2500_1110, .lpc175x, "LPC1751", sectors.lpc17xx_32k),

    // LPC18xx:
    Entry.make(0xF000_D830, .lpc185x, "LPC1850FET256", &.{}), // 0xXXXX_XX00
    Entry.make(0xF000_D830, .lpc185x, "LPC1850FET180", &.{}), // 0xXXXX_XX00
    Entry.make(0xF000_D860, .lpc185x, "LPC18S50FET256", &.{}), // 0xXXXX_XX00
    Entry.make(0xF000_D860, .lpc185x, "LPC18S50FET180", &.{}), // 0xXXXX_XX00
    Entry.make(0xF000_DA30, .lpc183x, "LPC1830FET256", &.{}), // 0xXXXX_XX00
    Entry.make(0xF000_DA30, .lpc183x, "LPC1830FET180", &.{}), // 0xXXXX_XX00
    Entry.make(0xF000_DA30, .lpc183x, "LPC1830FET100", &.{}), // 0xXXXX_XX00
    Entry.make(0xF000_DA30, .lpc183x, "LPC1830FBD144", &.{}), // 0xXXXX_XX00
    Entry.make(0xF000_DA60, .lpc183x, "LPC18S30FET256", &.{}), // 0xXXXX_XX00
    Entry.make(0xF000_DA60, .lpc183x, "LPC18S30FET100", &.{}), // 0xXXXX_XX00
    Entry.make(0xF000_DA60, .lpc183x, "LPC18S30FBD144", &.{}), // 0xXXXX_XX00
    Entry.make(0xF00A_DB3C, .lpc182x, "LPC1820FET100", &.{}), // 0xXXXX_XX00
    Entry.make(0xF00A_DB3C, .lpc182x, "LPC1820FBD144", &.{}), // 0xXXXX_XX00
    Entry.make(0xF00A_DB3C, .lpc182x, "LPC1820FBD100", &.{}), // 0xXXXX_XX00
    Entry.make(0xF00A_DB6C, .lpc182x, "LPC18S20FBD144", &.{}), // 0xXXXX_XX00
    Entry.make(0xF00B_5B3F, .lpc181x, "LPC1810FET100", &.{}), // 0xXXXX_XX00
    Entry.make(0xF00B_5B3F, .lpc181x, "LPC1810FBD144", &.{}), // 0xXXXX_XX00
    Entry.make(0xF00B_5B6F, .lpc181x, "LPC18S10FET100", &.{}), // 0xXXXX_XX00
    Entry.make(0xF00B_5B6F, .lpc181x, "LPC18S10FBD144", &.{}), // 0xXXXX_XX00
    Entry.make(0xF00B_5B6F, .lpc181x, "LPC18S10FET180", &.{}), // 0xXXXX_XX00
    Entry.make(0xF001_D830, .lpc185x, "LPC1857FET256", &.{}), // 0xXXXX_XX00
    Entry.make(0xF001_D830, .lpc185x, "LPC1857FET180", &.{}), // 0xXXXX_XX00
    Entry.make(0xF001_D830, .lpc185x, "LPC1857FBD208", &.{}), // 0xXXXX_XX00
    Entry.make(0xF001_D860, .lpc185x, "LPC18S57JBD208", &.{}), // 0xXXXX_XX00
    Entry.make(0xF001_D830, .lpc185x, "LPC1853FET256", &.{}), // 0xXXXX_XX44
    Entry.make(0xF001_D830, .lpc185x, "LPC1853FET180", &.{}), // 0xXXXX_XX44
    Entry.make(0xF001_D830, .lpc185x, "LPC1853FBD208", &.{}), // 0xXXXX_XX44
    Entry.make(0xF001_DA30, .lpc183x, "LPC1837FET256", &.{}), // 0xXXXX_XX00
    Entry.make(0xF001_DA30, .lpc183x, "LPC1837FET180", &.{}), // 0xXXXX_XX00
    Entry.make(0xF001_DA30, .lpc183x, "LPC1837FET100", &.{}), // 0xXXXX_XX00
    Entry.make(0xF001_DA30, .lpc183x, "LPC1837FBD144", &.{}), // 0xXXXX_XX00
    Entry.make(0xF001_DA60, .lpc183x, "LPC18S37JET100", &.{}), // 0xXXXX_XX00
    Entry.make(0xF001_DA60, .lpc183x, "LPC18S37JBD144", &.{}), // 0xXXXX_XX00
    Entry.make(0xF001_DA30, .lpc183x, "LPC1833FET256", &.{}), // 0xXXXX_XX44
    Entry.make(0xF001_DA30, .lpc183x, "LPC1833FET180", &.{}), // 0xXXXX_XX44
    Entry.make(0xF001_DA30, .lpc183x, "LPC1833FET100", &.{}), // 0xXXXX_XX44
    Entry.make(0xF001_DA30, .lpc183x, "LPC1833FBD144", &.{}), // 0xXXXX_XX44
    Entry.make(0xF001_DB3C, .lpc182x, "LPC1827JBD144", &.{}), // 0xXXXX_XX00
    Entry.make(0xF001_DB3C, .lpc182x, "LPC1827JET100", &.{}), // 0xXXXX_XX00
    Entry.make(0xF001_DB3C, .lpc182x, "LPC1825JBD144", &.{}), // 0xXXXX_XX22
    Entry.make(0xF001_DB3C, .lpc182x, "LPC1825JET100", &.{}), // 0xXXXX_XX22
    Entry.make(0xF00B_DB3C, .lpc182x, "LPC1823JBD144", &.{}), // 0xXXXX_XX44
    Entry.make(0xF00B_DB3C, .lpc182x, "LPC1823JET100", &.{}), // 0xXXXX_XX44
    Entry.make(0xF00B_DB3C, .lpc182x, "LPC1822JBD144", &.{}), // 0xXXXX_XX80
    Entry.make(0xF00B_DB3C, .lpc182x, "LPC1822JET100", &.{}), // 0xXXXX_XX80
    Entry.make(0xF001_DB3F, .lpc181x, "LPC1817JBD144", &.{}), // 0xXXXX_XX00
    Entry.make(0xF001_DB3F, .lpc181x, "LPC1817JET100", &.{}), // 0xXXXX_XX00
    Entry.make(0xF001_DB3F, .lpc181x, "LPC1815JBD144", &.{}), // 0xXXXX_XX22
    Entry.make(0xF001_DB3F, .lpc181x, "LPC1815JET100", &.{}), // 0xXXXX_XX22
    Entry.make(0xF00B_DB3F, .lpc181x, "LPC1813JBD144", &.{}), // 0xXXXX_XX44
    Entry.make(0xF00B_DB3F, .lpc181x, "LPC1813JET100", &.{}), // 0xXXXX_XX44
    Entry.make(0xF00B_DB3F, .lpc181x, "LPC1812JBD144", &.{}), // 0xXXXX_XX80
    Entry.make(0xF00B_DB3F, .lpc181x, "LPC1812JET100", &.{}), // 0xXXXX_XX80
};

const sectors = struct {
    const empty = &[_]Sector{};

    const lpc1100 = [_]Sector{
        Sector.make(0, 4, 0x0000_0000, 0x0000_0FFF),
        Sector.make(1, 4, 0x0000_1000, 0x0000_1FFF),
        Sector.make(2, 4, 0x0000_2000, 0x0000_2FFF),
        Sector.make(3, 4, 0x0000_3000, 0x0000_3FFF),
        Sector.make(4, 4, 0x0000_4000, 0x0000_4FFF),
        Sector.make(5, 4, 0x0000_5000, 0x0000_5FFF),
        Sector.make(6, 4, 0x0000_6000, 0x0000_6FFF),
        Sector.make(7, 4, 0x0000_7000, 0x0000_7FFF),
    };

    const lpc1110_4k = lpc1100[0..1];
    const lpc1111_8k = lpc1100[0..2];
    const lpc1112_16k = lpc1100[0..4];
    const lpc1113_24k = lpc1100[0..6];
    const lpc1114_32k = lpc1100[0..8];

    const lpc1100xl = [_]Sector{
        Sector.make(0, 4, 0x0000_0000, 0x0000_0FFF),
        Sector.make(1, 4, 0x0000_1000, 0x0000_1FFF),
        Sector.make(2, 4, 0x0000_2000, 0x0000_2FFF),
        Sector.make(3, 4, 0x0000_3000, 0x0000_3FFF),
        Sector.make(4, 4, 0x0000_4000, 0x0000_4FFF),
        Sector.make(5, 4, 0x0000_5000, 0x0000_5FFF),
        Sector.make(6, 4, 0x0000_6000, 0x0000_6FFF),
        Sector.make(7, 4, 0x0000_7000, 0x0000_7FFF),
        Sector.make(8, 4, 0x0000_8000, 0x0000_8FFF),
        Sector.make(9, 4, 0x0000_9000, 0x0000_9FFF),
        Sector.make(10, 4, 0x0000_A000, 0x0000_AFFF),
        Sector.make(11, 4, 0x0000_B000, 0x0000_BFFF),
        Sector.make(12, 4, 0x0000_C000, 0x0000_CFFF),
        Sector.make(13, 4, 0x0000_D000, 0x0000_DFFF),
        Sector.make(14, 4, 0x0000_E000, 0x0000_EFFF),
        Sector.make(15, 4, 0x0000_F000, 0x0000_FFFF),
    };

    const lpc1111xl_8k = lpc1100xl[0..2];
    const lpc1112xl_16k = lpc1100xl[0..4];
    const lpc1113xl_24k = lpc1100xl[0..6];
    const lpc1114xl_203_32k = lpc1100xl[0..8];
    const lpc1114xl_303_32k = lpc1100xl[0..8];
    const lpc1114xl_323_48k = lpc1100xl[0..12];
    const lpc1114xl_333_56k = lpc1100xl[0..14];
    const lpc1115xl_64k = lpc1100xl[0..16];

    const lpc17xx = [_]Sector{
        Sector.make(0, 4, 0x0000_0000, 0x0000_0FFF),
        Sector.make(1, 4, 0x0000_1000, 0x0000_1FFF),
        Sector.make(2, 4, 0x0000_2000, 0x0000_2FFF),
        Sector.make(3, 4, 0x0000_3000, 0x0000_3FFF),
        Sector.make(4, 4, 0x0000_4000, 0x0000_4FFF),
        Sector.make(5, 4, 0x0000_5000, 0x0000_5FFF),
        Sector.make(6, 4, 0x0000_6000, 0x0000_6FFF),
        Sector.make(7, 4, 0x0000_7000, 0x0000_7FFF),
        Sector.make(8, 4, 0x0000_8000, 0x0000_8FFF),
        Sector.make(9, 4, 0x0000_9000, 0x0000_9FFF),
        Sector.make(10, 4, 0x0000_A000, 0x0000_AFFF),
        Sector.make(11, 4, 0x0000_B000, 0x0000_BFFF),
        Sector.make(12, 4, 0x0000_C000, 0x0000_CFFF),
        Sector.make(13, 4, 0x0000_D000, 0x0000_DFFF),
        Sector.make(14, 4, 0x0000_E000, 0x0000_EFFF),
        Sector.make(15, 4, 0x0000_F000, 0x0000_FFFF),
        Sector.make(16, 32, 0x0001_0000, 0x0001_7FFF),
        Sector.make(17, 32, 0x0001_8000, 0x0001_FFFF),
        Sector.make(18, 32, 0x0002_0000, 0x0002_7FFF),
        Sector.make(19, 32, 0x0002_8000, 0x0002_FFFF),
        Sector.make(20, 32, 0x0003_0000, 0x0003_7FFF),
        Sector.make(21, 32, 0x0003_8000, 0x0003_FFFF),
        Sector.make(22, 32, 0x0004_0000, 0x0004_7FFF),
        Sector.make(23, 32, 0x0004_8000, 0x0004_FFFF),
        Sector.make(24, 32, 0x0005_0000, 0x0005_7FFF),
        Sector.make(25, 32, 0x0005_8000, 0x0005_FFFF),
        Sector.make(26, 32, 0x0006_0000, 0x0006_7FFF),
        Sector.make(27, 32, 0x0006_8000, 0x0006_FFFF),
        Sector.make(28, 32, 0x0007_0000, 0x0007_7FFF),
        Sector.make(29, 32, 0x0007_8000, 0x0007_FFFF),
    };

    const lpc17xx_32k = lpc17xx[0..8];
    const lpc17xx_64k = lpc17xx[0..16];
    const lpc17xx_128k = lpc17xx[0..18];
    const lpc17xx_256k = lpc17xx[0..22];
    const lpc17xx_512k = lpc17xx[0..30];
};
