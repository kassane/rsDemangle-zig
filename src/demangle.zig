const C = @cImport({
    @cInclude("stdlib.h");
    @cInclude("stdio.h");
    @cInclude("string.h");
});
const std = @import("std");

pub const demangle_callbackref = ?*const fn ([*c]const u8, usize, ?*anyopaque) callconv(.C) void;
pub const struct_rust_demangler = extern struct {
    sym: [*c]const u8,
    sym_len: usize,
    callback_opaque: ?*anyopaque,
    callback: demangle_callbackref,
    next: usize,
    errored: c_int,
    skipping_printing: c_int,
    verbose: c_int,
    version: c_int,
    bound_lifetime_depth: u64,
};
pub fn peek(arg_rdm: [*c]const struct_rust_demangler) callconv(.C) u8 {
    var rdm = arg_rdm;
    if (rdm.*.next < rdm.*.sym_len) return rdm.*.sym[rdm.*.next];
    return 0;
}
pub fn eat(arg_rdm: [*c]struct_rust_demangler, arg_c: u8) callconv(.C) c_int {
    var rdm = arg_rdm;
    var c = arg_c;
    if (@bitCast(c_int, @as(c_uint, peek(rdm))) == @bitCast(c_int, @as(c_uint, c))) {
        rdm.*.next +%= 1;
        return 1;
    } else return 0;
    return 0;
}
pub fn next(arg_rdm: [*c]struct_rust_demangler) callconv(.C) u8 {
    var rdm = arg_rdm;
    var c: u8 = peek(rdm);
    if (!(c != 0)) {
        rdm.*.errored = 1;
    } else {
        rdm.*.next +%= 1;
    }
    return c;
}
pub fn parse_integer_62(arg_rdm: [*c]struct_rust_demangler) callconv(.C) u64 {
    var rdm = arg_rdm;
    var c: u8 = undefined;
    var x: u64 = undefined;
    if (eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, '_')))) != 0) return 0;
    x = 0;
    while (!(eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, '_')))) != 0)) {
        c = next(rdm);
        x *%= @bitCast(c_ulong, @as(c_long, @as(c_int, 62)));
        if ((@bitCast(c_int, @as(c_uint, c)) >= @as(c_int, '0')) and (@bitCast(c_int, @as(c_uint, c)) <= @as(c_int, '9'))) {
            x +%= @bitCast(c_ulong, @as(c_long, @bitCast(c_int, @as(c_uint, c)) - @as(c_int, '0')));
        } else if ((@bitCast(c_int, @as(c_uint, c)) >= @as(c_int, 'a')) and (@bitCast(c_int, @as(c_uint, c)) <= @as(c_int, 'z'))) {
            x +%= @bitCast(c_ulong, @as(c_long, @as(c_int, 10) + (@bitCast(c_int, @as(c_uint, c)) - @as(c_int, 'a'))));
        } else if ((@bitCast(c_int, @as(c_uint, c)) >= @as(c_int, 'A')) and (@bitCast(c_int, @as(c_uint, c)) <= @as(c_int, 'Z'))) {
            x +%= @bitCast(c_ulong, @as(c_long, (@as(c_int, 10) + @as(c_int, 26)) + (@bitCast(c_int, @as(c_uint, c)) - @as(c_int, 'A'))));
        } else {
            rdm.*.errored = 1;
            return 0;
        }
    }
    return x +% @bitCast(c_ulong, @as(c_long, @as(c_int, 1)));
}
pub fn parse_opt_integer_62(arg_rdm: [*c]struct_rust_demangler, arg_tag: u8) callconv(.C) u64 {
    var rdm = arg_rdm;
    var tag = arg_tag;
    if (!(eat(rdm, tag) != 0)) return 0;
    return @bitCast(c_ulong, @as(c_long, @as(c_int, 1))) +% parse_integer_62(rdm);
}
pub fn parse_disambiguator(arg_rdm: [*c]struct_rust_demangler) callconv(.C) u64 {
    var rdm = arg_rdm;
    return parse_opt_integer_62(rdm, @bitCast(u8, @truncate(i8, @as(c_int, 's'))));
}
pub const struct_rust_mangled_ident = extern struct {
    ascii: [*c]const u8,
    ascii_len: usize,
    punycode: [*c]const u8,
    punycode_len: usize,
};
pub fn parse_ident(arg_rdm: [*c]struct_rust_demangler) callconv(.C) struct_rust_mangled_ident {
    var rdm = arg_rdm;
    var c: u8 = undefined;
    var start: usize = undefined;
    var len: usize = undefined;
    var is_punycode: c_int = 0;
    var ident: struct_rust_mangled_ident = undefined;
    ident.ascii = null;
    ident.ascii_len = 0;
    ident.punycode = null;
    ident.punycode_len = 0;
    if (rdm.*.version != -@as(c_int, 1)) {
        is_punycode = eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, 'u'))));
    }
    c = next(rdm);
    if (!((@bitCast(c_int, @as(c_uint, c)) >= @as(c_int, '0')) and (@bitCast(c_int, @as(c_uint, c)) <= @as(c_int, '9')))) {
        rdm.*.errored = 1;
        return ident;
    }
    len = @bitCast(usize, @as(c_long, @bitCast(c_int, @as(c_uint, c)) - @as(c_int, '0')));
    if (@bitCast(c_int, @as(c_uint, c)) != @as(c_int, '0')) while ((@bitCast(c_int, @as(c_uint, peek(rdm))) >= @as(c_int, '0')) and (@bitCast(c_int, @as(c_uint, peek(rdm))) <= @as(c_int, '9'))) {
        len = (len *% @bitCast(c_ulong, @as(c_long, @as(c_int, 10)))) +% @bitCast(c_ulong, @as(c_long, @bitCast(c_int, @as(c_uint, next(rdm))) - @as(c_int, '0')));
    };
    if (rdm.*.version != -@as(c_int, 1)) {
        _ = eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, '_'))));
    }
    start = rdm.*.next;
    rdm.*.next +%= len;
    if ((start > rdm.*.next) or (rdm.*.next > rdm.*.sym_len)) {
        rdm.*.errored = 1;
        return ident;
    }
    ident.ascii = rdm.*.sym + start;
    ident.ascii_len = len;
    if (is_punycode != 0) {
        ident.punycode_len = 0;
        while (ident.ascii_len > @bitCast(c_ulong, @as(c_long, @as(c_int, 0)))) {
            ident.ascii_len -%= 1;
            if (@bitCast(c_int, @as(c_uint, ident.ascii[ident.ascii_len])) == @as(c_int, '_')) break;
            ident.punycode_len +%= 1;
        }
        if (!(ident.punycode_len != 0)) {
            rdm.*.errored = 1;
            return ident;
        }
        ident.punycode = ident.ascii + (len -% ident.punycode_len);
    }
    if (ident.ascii_len == @bitCast(c_ulong, @as(c_long, @as(c_int, 0)))) {
        ident.ascii = null;
    }
    return ident;
}
pub fn print_str(arg_rdm: [*c]struct_rust_demangler, arg_data: [*c]const u8, arg_len: usize) callconv(.C) void {
    var rdm = arg_rdm;
    var data = arg_data;
    var len = arg_len;
    if (!(rdm.*.errored != 0) and !(rdm.*.skipping_printing != 0)) {
        rdm.*.callback.?(data, len, rdm.*.callback_opaque);
    }
}
pub fn print_uint64(arg_rdm: [*c]struct_rust_demangler, arg_x: u64) callconv(.C) void {
    var rdm = arg_rdm;
    var s: [21]u8 = undefined;
    var x = std.fmt.bufPrintZ(&s, "{d}", .{arg_x}) catch @panic("fmt error");
    print_str(rdm, x, x.len);
}
pub fn print_uint64_hex(arg_rdm: [*c]struct_rust_demangler, arg_x: u64) callconv(.C) void {
    var rdm = arg_rdm;
    var s: [17]u8 = undefined;
    var x = std.fmt.bufPrintZ(&s, "{d}", .{arg_x}) catch @panic("fmt error");
    print_str(rdm, x, x.len);
}
pub fn decode_lower_hex_nibble(arg_nibble: u8) callconv(.C) c_int {
    var nibble = arg_nibble;
    if ((@as(c_int, '0') <= @bitCast(c_int, @as(c_uint, nibble))) and (@bitCast(c_int, @as(c_uint, nibble)) <= @as(c_int, '9'))) return @bitCast(c_int, @as(c_uint, nibble)) - @as(c_int, '0');
    if ((@as(c_int, 'a') <= @bitCast(c_int, @as(c_uint, nibble))) and (@bitCast(c_int, @as(c_uint, nibble)) <= @as(c_int, 'f'))) return @as(c_int, 10) + (@bitCast(c_int, @as(c_uint, nibble)) - @as(c_int, 'a'));
    return -@as(c_int, 1);
}
pub fn decode_legacy_escape(arg_e: [*c]const u8, arg_len: usize, arg_out_len: [*c]usize) callconv(.C) u8 {
    var e = arg_e;
    var len = arg_len;
    var out_len = arg_out_len;
    var c: u8 = 0;
    var escape_len: usize = 0;
    var lo_nibble: c_int = -@as(c_int, 1);
    var hi_nibble: c_int = -@as(c_int, 1);
    if ((len < @bitCast(c_ulong, @as(c_long, @as(c_int, 3)))) or (@bitCast(c_int, @as(c_uint, e[@intCast(c_uint, @as(c_int, 0))])) != @as(c_int, '$'))) return 0;
    e += 1;
    len -%= 1;
    if (@bitCast(c_int, @as(c_uint, e[@intCast(c_uint, @as(c_int, 0))])) == @as(c_int, 'C')) {
        escape_len = 1;
        c = ',';
    } else if (len > @bitCast(c_ulong, @as(c_long, @as(c_int, 2)))) {
        escape_len = 2;
        if ((@bitCast(c_int, @as(c_uint, e[@intCast(c_uint, @as(c_int, 0))])) == @as(c_int, 'S')) and (@bitCast(c_int, @as(c_uint, e[@intCast(c_uint, @as(c_int, 1))])) == @as(c_int, 'P'))) {
            c = '@';
        } else if ((@bitCast(c_int, @as(c_uint, e[@intCast(c_uint, @as(c_int, 0))])) == @as(c_int, 'B')) and (@bitCast(c_int, @as(c_uint, e[@intCast(c_uint, @as(c_int, 1))])) == @as(c_int, 'P'))) {
            c = '*';
        } else if ((@bitCast(c_int, @as(c_uint, e[@intCast(c_uint, @as(c_int, 0))])) == @as(c_int, 'R')) and (@bitCast(c_int, @as(c_uint, e[@intCast(c_uint, @as(c_int, 1))])) == @as(c_int, 'F'))) {
            c = '&';
        } else if ((@bitCast(c_int, @as(c_uint, e[@intCast(c_uint, @as(c_int, 0))])) == @as(c_int, 'L')) and (@bitCast(c_int, @as(c_uint, e[@intCast(c_uint, @as(c_int, 1))])) == @as(c_int, 'T'))) {
            c = '<';
        } else if ((@bitCast(c_int, @as(c_uint, e[@intCast(c_uint, @as(c_int, 0))])) == @as(c_int, 'G')) and (@bitCast(c_int, @as(c_uint, e[@intCast(c_uint, @as(c_int, 1))])) == @as(c_int, 'T'))) {
            c = '>';
        } else if ((@bitCast(c_int, @as(c_uint, e[@intCast(c_uint, @as(c_int, 0))])) == @as(c_int, 'L')) and (@bitCast(c_int, @as(c_uint, e[@intCast(c_uint, @as(c_int, 1))])) == @as(c_int, 'P'))) {
            c = '(';
        } else if ((@bitCast(c_int, @as(c_uint, e[@intCast(c_uint, @as(c_int, 0))])) == @as(c_int, 'R')) and (@bitCast(c_int, @as(c_uint, e[@intCast(c_uint, @as(c_int, 1))])) == @as(c_int, 'P'))) {
            c = ')';
        } else if ((@bitCast(c_int, @as(c_uint, e[@intCast(c_uint, @as(c_int, 0))])) == @as(c_int, 'u')) and (len > @bitCast(c_ulong, @as(c_long, @as(c_int, 3))))) {
            escape_len = 3;
            hi_nibble = decode_lower_hex_nibble(e[@intCast(c_uint, @as(c_int, 1))]);
            if (hi_nibble < @as(c_int, 0)) return 0;
            lo_nibble = decode_lower_hex_nibble(e[@intCast(c_uint, @as(c_int, 2))]);
            if (lo_nibble < @as(c_int, 0)) return 0;
            if (hi_nibble > @as(c_int, 7)) return 0;
            c = @bitCast(u8, @truncate(i8, (hi_nibble << @intCast(std.math.Log2Int(c_int), 4)) | lo_nibble));
            if (@bitCast(c_int, @as(c_uint, c)) < @as(c_int, 32)) return 0;
        }
    }
    if ((!(c != 0) or (len <= escape_len)) or (@bitCast(c_int, @as(c_uint, e[escape_len])) != @as(c_int, '$'))) return 0;
    out_len.* = @bitCast(c_ulong, @as(c_long, @as(c_int, 2))) +% escape_len;
    return c;
}
pub fn print_ident(arg_rdm: [*c]struct_rust_demangler, arg_ident: struct_rust_mangled_ident) callconv(.C) void {
    var rdm = arg_rdm;
    var ident = arg_ident;
    var unescaped: u8 = undefined;
    var out: [*c]u8 = undefined;
    var p: [*c]u8 = undefined;
    var d: u8 = undefined;
    var len: usize = undefined;
    var cap: usize = undefined;
    var punycode_pos: usize = undefined;
    var j: usize = undefined;
    var c: u32 = undefined;
    var base: usize = undefined;
    var t_min: usize = undefined;
    var t_max: usize = undefined;
    var skew: usize = undefined;
    var damp: usize = undefined;
    var bias: usize = undefined;
    var i: usize = undefined;
    var delta: usize = undefined;
    var w: usize = undefined;
    var k: usize = undefined;
    var t: usize = undefined;
    var @"error": c_int = 0;
    if ((rdm.*.errored != 0) or (rdm.*.skipping_printing != 0)) return;
    if (rdm.*.version == -@as(c_int, 1)) {
        if (((ident.ascii_len >= @bitCast(c_ulong, @as(c_long, @as(c_int, 2)))) and (@bitCast(c_int, @as(c_uint, ident.ascii[@intCast(c_uint, @as(c_int, 0))])) == @as(c_int, '_'))) and (@bitCast(c_int, @as(c_uint, ident.ascii[@intCast(c_uint, @as(c_int, 1))])) == @as(c_int, '$'))) {
            ident.ascii += 1;
            ident.ascii_len -%= 1;
        }
        while (ident.ascii_len > @bitCast(c_ulong, @as(c_long, @as(c_int, 0)))) {
            if (@bitCast(c_int, @as(c_uint, ident.ascii[@intCast(c_uint, @as(c_int, 0))])) == @as(c_int, '$')) {
                unescaped = decode_legacy_escape(ident.ascii, ident.ascii_len, &len);
                if (unescaped != 0) {
                    print_str(rdm, &unescaped, @bitCast(usize, @as(c_long, @as(c_int, 1))));
                } else {
                    print_str(rdm, ident.ascii, ident.ascii_len);
                    return;
                }
            } else if (@bitCast(c_int, @as(c_uint, ident.ascii[@intCast(c_uint, @as(c_int, 0))])) == @as(c_int, '.')) {
                if ((ident.ascii_len >= @bitCast(c_ulong, @as(c_long, @as(c_int, 2)))) and (@bitCast(c_int, @as(c_uint, ident.ascii[@intCast(c_uint, @as(c_int, 1))])) == @as(c_int, '.'))) {
                    print_str(rdm, "::", std.mem.len("::"));
                    len = 2;
                } else {
                    print_str(rdm, "-", std.mem.len("-"));
                    len = 1;
                }
            } else {
                {
                    len = 0;
                    while (len < ident.ascii_len) : (len +%= 1) if ((@bitCast(c_int, @as(c_uint, ident.ascii[len])) == @as(c_int, '$')) or (@bitCast(c_int, @as(c_uint, ident.ascii[len])) == @as(c_int, '.'))) break;
                }
                print_str(rdm, ident.ascii, len);
            }
            ident.ascii += len;
            ident.ascii_len -%= len;
        }
        return;
    }
    if (!(ident.punycode != null)) {
        print_str(rdm, ident.ascii, ident.ascii_len);
        return;
    }
    len = 0;
    cap = 4;
    while (cap < ident.ascii_len) {
        cap *%= @bitCast(c_ulong, @as(c_long, @as(c_int, 2)));
        if (((cap *% @bitCast(c_ulong, @as(c_long, @as(c_int, 4)))) / @bitCast(c_ulong, @as(c_long, @as(c_int, 4)))) != cap) {
            rdm.*.errored = 1;
            return;
        }
    }
    out = @ptrCast([*c]u8, @alignCast(std.meta.alignment([*c]u8), std.c.malloc(cap * 4)));
    if (!(out != null)) {
        rdm.*.errored = 1;
        return;
    }
    {
        len = 0;
        while (len < ident.ascii_len) : (len +%= 1) {
            p = out + (@bitCast(c_ulong, @as(c_long, @as(c_int, 4))) *% len);
            p[@intCast(c_uint, @as(c_int, 0))] = 0;
            p[@intCast(c_uint, @as(c_int, 1))] = 0;
            p[@intCast(c_uint, @as(c_int, 2))] = 0;
            p[@intCast(c_uint, @as(c_int, 3))] = @bitCast(u8, ident.ascii[len]);
        }
    }
    base = 36;
    t_min = 1;
    t_max = 26;
    skew = 38;
    damp = @bitCast(usize, @as(c_long, @as(c_int, 700)));
    bias = 72;
    i = 0;
    c = 128;
    punycode_pos = 0;
    while (punycode_pos < ident.punycode_len) {
        delta = 0;
        w = 1;
        k = 0;
        while (true) {
            k +%= base;
            t = if (k < bias) @bitCast(c_ulong, @as(c_long, @as(c_int, 0))) else k -% bias;
            if (t < t_min) {
                t = t_min;
            }
            if (t > t_max) {
                t = t_max;
            }
            if (punycode_pos >= ident.punycode_len) {
                @"error" = -@as(c_int, 1);
            }
            d = @bitCast(u8, ident.punycode[
                blk: {
                    const ref = &punycode_pos;
                    const tmp = ref.*;
                    ref.* +%= 1;
                    break :blk tmp;
                }
            ]);
            if ((@bitCast(c_int, @as(c_uint, d)) >= @as(c_int, 'a')) and (@bitCast(c_int, @as(c_uint, d)) <= @as(c_int, 'z'))) {
                d = @bitCast(u8, @truncate(i8, @bitCast(c_int, @as(c_uint, d)) - @as(c_int, 'a')));
            } else if ((@bitCast(c_int, @as(c_uint, d)) >= @as(c_int, '0')) and (@bitCast(c_int, @as(c_uint, d)) <= @as(c_int, '9'))) {
                d = @bitCast(u8, @truncate(i8, @as(c_int, 26) + (@bitCast(c_int, @as(c_uint, d)) - @as(c_int, '0'))));
            } else {
                rdm.*.errored = 1;
                @"error" = -@as(c_int, 1);
            }
            delta +%= @bitCast(c_ulong, @as(c_ulong, d)) *% w;
            w *%= base -% t;
            if (!(@bitCast(c_ulong, @as(c_ulong, d)) >= t)) break;
        }
        len +%= 1;
        i +%= delta;
        c +%= @bitCast(u32, @truncate(c_uint, i / len));
        i %= len;
        if (cap < len) {
            cap *%= @bitCast(c_ulong, @as(c_long, @as(c_int, 2)));
            if ((((cap *% @bitCast(c_ulong, @as(c_long, @as(c_int, 4)))) / @bitCast(c_ulong, @as(c_long, @as(c_int, 4)))) != cap) or (cap < len)) {
                rdm.*.errored = 1;
                @"error" = -@as(c_int, 1);
            }
        }
        p = @ptrCast([*c]u8, @alignCast(std.meta.alignment([*c]u8), std.c.realloc(out, cap * 4)));
        if (!(p != null)) {
            rdm.*.errored = 1;
            @"error" = -@as(c_int, 1);
        }
        out = p;
        p = out + (i *% @bitCast(c_ulong, @as(c_long, @as(c_int, 4))));
        _ = C.memmove(@ptrCast(?*anyopaque, p + 4), @ptrCast(?*const anyopaque, p), ((len -% i) -% 1) *% 4);
        p[@intCast(c_uint, @as(c_int, 0))] = @bitCast(u8, @truncate(u8, if (c >= @bitCast(c_uint, @as(c_int, 65536))) @bitCast(c_uint, @as(c_int, 240)) | (c >> @intCast(u5, 18)) else @bitCast(c_uint, @as(c_int, 0))));
        p[@intCast(c_uint, @as(c_int, 1))] = @bitCast(u8, @truncate(u8, if (c >= @bitCast(c_uint, @as(c_int, 2048))) @bitCast(c_uint, if (c < @bitCast(c_uint, @as(c_int, 65536))) @as(c_int, 224) else @as(c_int, 128)) | ((c >> @intCast(u5, 12)) & @bitCast(c_uint, @as(c_int, 63))) else @bitCast(c_uint, @as(c_int, 0))));
        p[@intCast(c_uint, @as(c_int, 2))] = @bitCast(u8, @truncate(u8, @bitCast(c_uint, if (c < @bitCast(c_uint, @as(c_int, 2048))) @as(c_int, 192) else @as(c_int, 128)) | ((c >> @intCast(u5, 6)) & @bitCast(c_uint, @as(c_int, 63)))));
        p[@intCast(c_uint, @as(c_int, 3))] = @bitCast(u8, @truncate(u8, @bitCast(c_uint, @as(c_int, 128)) | (c & @bitCast(c_uint, @as(c_int, 63)))));
        if (punycode_pos == ident.punycode_len) break;
        i +%= 1;
        delta /= damp;
        damp = 2;
        delta +%= delta / len;
        k = 0;
        while (delta > (((base -% t_min) *% t_max) / @bitCast(c_ulong, @as(c_long, @as(c_int, 2))))) {
            delta /= base -% t_min;
            k +%= base;
        }
        bias = k +% ((((base -% t_min) +% @bitCast(c_ulong, @as(c_long, @as(c_int, 1)))) *% delta) / (delta +% skew));
    }
    {
        _ = blk: {
            i = 0;
            break :blk blk_1: {
                const tmp = @bitCast(usize, @as(c_long, @as(c_int, 0)));
                j = tmp;
                break :blk_1 tmp;
            };
        };
        while (i < (len *% @bitCast(c_ulong, @as(c_long, @as(c_int, 4))))) : (i +%= 1) if (@bitCast(c_int, @as(c_uint, out[i])) != @as(c_int, 0)) {
            out[
                blk: {
                    const ref = &j;
                    const tmp = ref.*;
                    ref.* +%= 1;
                    break :blk tmp;
                }
            ] = out[i];
        };
    }
    print_str(rdm, @ptrCast([*c]const u8, @alignCast(std.meta.alignment([*c]const u8), out)), j);
    if (@"error" != @as(c_int, 0)) {
        std.c.free(out);
    }
}
pub fn print_lifetime_from_index(arg_rdm: [*c]struct_rust_demangler, arg_lt: u64) callconv(.C) void {
    var rdm = arg_rdm;
    var lt = arg_lt;
    var c: u8 = undefined;
    var depth: u64 = undefined;
    print_str(rdm, "'", std.mem.len("'"));
    if (lt == @bitCast(c_ulong, @as(c_long, @as(c_int, 0)))) {
        print_str(rdm, "_", std.mem.len("_"));
        return;
    }
    depth = rdm.*.bound_lifetime_depth -% lt;
    if (depth < @bitCast(c_ulong, @as(c_long, @as(c_int, 26)))) {
        c = @bitCast(u8, @truncate(u8, @bitCast(c_ulong, @as(c_long, @as(c_int, 'a'))) +% depth));
        print_str(rdm, &c, @bitCast(usize, @as(c_long, @as(c_int, 1))));
    } else {
        print_str(rdm, "_", std.mem.len("_"));
        print_uint64(rdm, depth);
    }
}
pub fn demangle_binder(arg_rdm: [*c]struct_rust_demangler) callconv(.C) void {
    var rdm = arg_rdm;
    var i: u64 = undefined;
    var bound_lifetimes: u64 = undefined;
    if (rdm.*.errored != 0) return;
    bound_lifetimes = parse_opt_integer_62(rdm, @bitCast(u8, @truncate(i8, @as(c_int, 'G'))));
    if (bound_lifetimes > @bitCast(c_ulong, @as(c_long, @as(c_int, 0)))) {
        print_str(rdm, "for<", std.mem.len("for<"));
        {
            i = 0;
            while (i < bound_lifetimes) : (i +%= 1) {
                if (i > @bitCast(c_ulong, @as(c_long, @as(c_int, 0)))) {
                    print_str(rdm, ", ", std.mem.len(", "));
                }
                rdm.*.bound_lifetime_depth +%= 1;
                print_lifetime_from_index(rdm, @bitCast(u64, @as(c_long, @as(c_int, 1))));
            }
        }
        print_str(rdm, "> ", std.mem.len("> "));
    }
}
pub fn demangle_path(arg_rdm: [*c]struct_rust_demangler, arg_in_value: c_int) callconv(.C) void {
    var rdm = arg_rdm;
    var in_value = arg_in_value;
    var tag: u8 = undefined;
    var ns: u8 = undefined;
    var was_skipping_printing: c_int = undefined;
    var i: usize = undefined;
    var backref: usize = undefined;
    var old_next: usize = undefined;
    var dis: u64 = undefined;
    var name: struct_rust_mangled_ident = undefined;
    if (rdm.*.errored != 0) return;
    while (true) {
        switch (@bitCast(c_int, @as(c_uint, blk: {
            const tmp = next(rdm);
            tag = tmp;
            break :blk tmp;
        }))) {
            @as(c_int, 67) => {
                dis = parse_disambiguator(rdm);
                name = parse_ident(rdm);
                print_ident(rdm, name);
                if (rdm.*.verbose != 0) {
                    print_str(rdm, "[", std.mem.len("["));
                    print_uint64_hex(rdm, dis);
                    print_str(rdm, "]", std.mem.len("]"));
                }
                break;
            },
            @as(c_int, 78) => {
                ns = next(rdm);
                if (!((@bitCast(c_int, @as(c_uint, ns)) >= @as(c_int, 'a')) and (@bitCast(c_int, @as(c_uint, ns)) <= @as(c_int, 'z'))) and !((@bitCast(c_int, @as(c_uint, ns)) >= @as(c_int, 'A')) and (@bitCast(c_int, @as(c_uint, ns)) <= @as(c_int, 'Z')))) {
                    rdm.*.errored = 1;
                    return;
                }
                demangle_path(rdm, in_value);
                dis = parse_disambiguator(rdm);
                name = parse_ident(rdm);
                if ((@bitCast(c_int, @as(c_uint, ns)) >= @as(c_int, 'A')) and (@bitCast(c_int, @as(c_uint, ns)) <= @as(c_int, 'Z'))) {
                    print_str(rdm, "::{", std.mem.len("::{"));
                    while (true) {
                        switch (@bitCast(c_int, @as(c_uint, ns))) {
                            @as(c_int, 67) => {
                                print_str(rdm, "closure", std.mem.len("closure"));
                                break;
                            },
                            @as(c_int, 83) => {
                                print_str(rdm, "shim", std.mem.len("shim"));
                                break;
                            },
                            else => {
                                print_str(rdm, &ns, @bitCast(usize, @as(c_long, @as(c_int, 1))));
                            },
                        }
                        break;
                    }
                    if ((name.ascii != null) or (name.punycode != null)) {
                        print_str(rdm, ":", std.mem.len(":"));
                        print_ident(rdm, name);
                    }
                    print_str(rdm, "#", std.mem.len("#"));
                    print_uint64(rdm, dis);
                    print_str(rdm, "}", std.mem.len("}"));
                } else {
                    if ((name.ascii != null) or (name.punycode != null)) {
                        print_str(rdm, "::", std.mem.len("::"));
                        print_ident(rdm, name);
                    }
                }
                break;
            },
            @as(c_int, 77), @as(c_int, 88) => {
                _ = parse_disambiguator(rdm);
                was_skipping_printing = rdm.*.skipping_printing;
                rdm.*.skipping_printing = 1;
                demangle_path(rdm, in_value);
                rdm.*.skipping_printing = was_skipping_printing;
                print_str(rdm, "<", std.mem.len("<"));
                demangle_type(rdm);
                if (@bitCast(c_int, @as(c_uint, tag)) != @as(c_int, 'M')) {
                    print_str(rdm, " as ", std.mem.len(" as "));
                    demangle_path(rdm, @as(c_int, 0));
                }
                print_str(rdm, ">", std.mem.len(">"));
                break;
            },
            @as(c_int, 89) => {
                print_str(rdm, "<", std.mem.len("<"));
                demangle_type(rdm);
                if (@bitCast(c_int, @as(c_uint, tag)) != @as(c_int, 'M')) {
                    print_str(rdm, " as ", std.mem.len(" as "));
                    demangle_path(rdm, @as(c_int, 0));
                }
                print_str(rdm, ">", std.mem.len(">"));
                break;
            },
            @as(c_int, 73) => {
                demangle_path(rdm, in_value);
                if (in_value != 0) {
                    print_str(rdm, "::", std.mem.len("::"));
                }
                print_str(rdm, "<", std.mem.len("<"));
                {
                    i = 0;
                    while (!(rdm.*.errored != 0) and !(eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, 'E')))) != 0)) : (i +%= 1) {
                        if (i > @bitCast(c_ulong, @as(c_long, @as(c_int, 0)))) {
                            print_str(rdm, ", ", std.mem.len(", "));
                        }
                        demangle_generic_arg(rdm);
                    }
                }
                print_str(rdm, ">", std.mem.len(">"));
                break;
            },
            @as(c_int, 66) => {
                backref = parse_integer_62(rdm);
                if (!(rdm.*.skipping_printing != 0)) {
                    old_next = rdm.*.next;
                    rdm.*.next = backref;
                    demangle_path(rdm, in_value);
                    rdm.*.next = old_next;
                }
                break;
            },
            else => {
                rdm.*.errored = 1;
                return;
            },
        }
        break;
    }
}
pub fn demangle_generic_arg(arg_rdm: [*c]struct_rust_demangler) callconv(.C) void {
    var rdm = arg_rdm;
    var lt: u64 = undefined;
    if (eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, 'L')))) != 0) {
        lt = parse_integer_62(rdm);
        print_lifetime_from_index(rdm, lt);
    } else if (eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, 'K')))) != 0) {
        demangle_const(rdm);
    } else {
        demangle_type(rdm);
    }
}
// src/rust-demangle.c:834:3: warning: TODO implement translation of stmt class LabelStmtClass
// src/rust-demangle.c:717:13: warning: unable to translate function, demoted to extern
pub fn demangle_type(arg_rdm: [*c]struct_rust_demangler) callconv(.C) void {
    var rdm = arg_rdm;
    var tag: u8 = undefined;
    var i: usize = undefined;
    var old_next: usize = undefined;
    var backref: usize = undefined;
    var lt: u64 = undefined;
    var old_bound_lifetime_depth: u64 = undefined;
    var basic: [*c]const u8 = undefined;
    var abi: struct_rust_mangled_ident = undefined;
    var @"error": c_int = 0;
    _ = @TypeOf(@"error");
    if (rdm.*.errored != 0) return;
    tag = next(rdm);
    basic = basic_type(tag);
    if (basic != null) {
        print_str(rdm, basic, std.mem.len(basic));
        return;
    }
    while (true) {
        switch (@bitCast(c_int, @as(c_uint, tag))) {
            @as(c_int, 82), @as(c_int, 81) => {
                print_str(rdm, "&", std.mem.len("&"));
                if (eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, 'L')))) != 0) {
                    lt = parse_integer_62(rdm);
                    if (lt != 0) {
                        print_lifetime_from_index(rdm, lt);
                        print_str(rdm, " ", std.mem.len(" "));
                    }
                }
                if (@bitCast(c_int, @as(c_uint, tag)) != @as(c_int, 'R')) {
                    print_str(rdm, "mut ", std.mem.len("mut "));
                }
                demangle_type(rdm);
                break;
            },
            @as(c_int, 80), @as(c_int, 79) => {
                print_str(rdm, "*", std.mem.len("*"));
                if (@bitCast(c_int, @as(c_uint, tag)) != @as(c_int, 'P')) {
                    print_str(rdm, "mut ", std.mem.len("mut "));
                } else {
                    print_str(rdm, "const ", std.mem.len("const "));
                }
                demangle_type(rdm);
                break;
            },
            @as(c_int, 65), @as(c_int, 83) => {
                print_str(rdm, "[", std.mem.len("["));
                demangle_type(rdm);
                if (@bitCast(c_int, @as(c_uint, tag)) == @as(c_int, 'A')) {
                    print_str(rdm, "; ", std.mem.len("; "));
                    demangle_const(rdm);
                }
                print_str(rdm, "]", std.mem.len("]"));
                break;
            },
            @as(c_int, 84) => {
                print_str(rdm, "(", std.mem.len("("));
                {
                    i = 0;
                    while (!(rdm.*.errored != 0) and !(eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, 'E')))) != 0)) : (i +%= 1) {
                        if (i > @bitCast(c_ulong, @as(c_long, @as(c_int, 0)))) {
                            print_str(rdm, ", ", std.mem.len(", "));
                        }
                        demangle_type(rdm);
                    }
                }
                if (i == @bitCast(c_ulong, @as(c_long, @as(c_int, 1)))) {
                    print_str(rdm, ",", std.mem.len(","));
                }
                print_str(rdm, ")", std.mem.len(")"));
                break;
            },
            @as(c_int, 70) => {
                old_bound_lifetime_depth = rdm.*.bound_lifetime_depth;
                demangle_binder(rdm);
                if (eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, 'U')))) != 0) {
                    print_str(rdm, "unsafe ", std.mem.len("unsafe "));
                }
                if (eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, 'K')))) != 0) {
                    if (eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, 'C')))) != 0) {
                        abi.ascii = "C";
                        abi.ascii_len = 1;
                    } else {
                        abi = parse_ident(rdm);
                        if (!(abi.ascii != null) or (abi.punycode != null)) {
                            rdm.*.errored = 1;
                            break;
                        }
                    }
                    print_str(rdm, "extern \"", std.mem.len("extern \""));
                    {
                        i = 0;
                        while (i < abi.ascii_len) : (i +%= 1) {
                            if (@bitCast(c_int, @as(c_uint, abi.ascii[i])) == @as(c_int, '_')) {
                                print_str(rdm, abi.ascii, i);
                                print_str(rdm, "-", std.mem.len("-"));
                                abi.ascii += i +% @bitCast(c_ulong, @as(c_long, @as(c_int, 1)));
                                abi.ascii_len -%= i +% @bitCast(c_ulong, @as(c_long, @as(c_int, 1)));
                                i = 0;
                            }
                        }
                    }
                    print_str(rdm, abi.ascii, abi.ascii_len);
                    print_str(rdm, "\" ", std.mem.len("\" "));
                }
                print_str(rdm, "fn(", std.mem.len("fn("));
                {
                    i = 0;
                    while (!(rdm.*.errored != 0) and !(eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, 'E')))) != 0)) : (i +%= 1) {
                        if (i > @bitCast(c_ulong, @as(c_long, @as(c_int, 0)))) {
                            print_str(rdm, ", ", std.mem.len(", "));
                        }
                        demangle_type(rdm);
                    }
                }
                print_str(rdm, ")", std.mem.len(")"));
                if (eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, 'u')))) != 0) {} else {
                    print_str(rdm, " -> ", std.mem.len(" -> "));
                    demangle_type(rdm);
                }
                rdm.*.bound_lifetime_depth = old_bound_lifetime_depth;
                break;
            },
            @as(c_int, 68) => {
                print_str(rdm, "dyn ", std.mem.len("dyn "));
                old_bound_lifetime_depth = rdm.*.bound_lifetime_depth;
                demangle_binder(rdm);
                {
                    i = 0;
                    while (!(rdm.*.errored != 0) and !(eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, 'E')))) != 0)) : (i +%= 1) {
                        if (i > @bitCast(c_ulong, @as(c_long, @as(c_int, 0)))) {
                            print_str(rdm, " + ", std.mem.len(" + "));
                        }
                        demangle_dyn_trait(rdm);
                    }
                }
                rdm.*.bound_lifetime_depth = old_bound_lifetime_depth;
                if (!(eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, 'L')))) != 0)) {
                    rdm.*.errored = 1;
                    return;
                }
                lt = parse_integer_62(rdm);
                if (lt != 0) {
                    print_str(rdm, " + ", std.mem.len(" + "));
                    print_lifetime_from_index(rdm, lt);
                }
                break;
            },
            @as(c_int, 66) => {
                backref = parse_integer_62(rdm);
                if (!(rdm.*.skipping_printing != 0)) {
                    old_next = rdm.*.next;
                    rdm.*.next = backref;
                    demangle_type(rdm);
                    rdm.*.next = old_next;
                }
                break;
            },
            else => {
                rdm.*.next -%= 1;
                demangle_path(rdm, @as(c_int, 0));
            },
        }
        break;
    }
}
pub fn demangle_path_maybe_open_generics(arg_rdm: [*c]struct_rust_demangler) callconv(.C) c_int {
    var rdm = arg_rdm;
    var open: c_int = undefined;
    var i: usize = undefined;
    var old_next: usize = undefined;
    var backref: usize = undefined;
    open = 0;
    if (rdm.*.errored != 0) return open;
    if (eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, 'B')))) != 0) {
        backref = parse_integer_62(rdm);
        if (!(rdm.*.skipping_printing != 0)) {
            old_next = rdm.*.next;
            rdm.*.next = backref;
            open = demangle_path_maybe_open_generics(rdm);
            rdm.*.next = old_next;
        }
    } else if (eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, 'I')))) != 0) {
        demangle_path(rdm, @as(c_int, 0));
        print_str(rdm, "<", std.mem.len("<"));
        open = 1;
        {
            i = 0;
            while (!(rdm.*.errored != 0) and !(eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, 'E')))) != 0)) : (i +%= 1) {
                if (i > @bitCast(c_ulong, @as(c_long, @as(c_int, 0)))) {
                    print_str(rdm, ", ", std.mem.len(", "));
                }
                demangle_generic_arg(rdm);
            }
        }
    } else {
        demangle_path(rdm, @as(c_int, 0));
    }
    return open;
}
pub fn demangle_dyn_trait(arg_rdm: [*c]struct_rust_demangler) callconv(.C) void {
    var rdm = arg_rdm;
    var open: c_int = undefined;
    var name: struct_rust_mangled_ident = undefined;
    if (rdm.*.errored != 0) return;
    open = demangle_path_maybe_open_generics(rdm);
    while (eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, 'p')))) != 0) {
        if (!(open != 0)) {
            print_str(rdm, "<", std.mem.len("<"));
        } else {
            print_str(rdm, ", ", std.mem.len(", "));
        }
        open = 1;
        name = parse_ident(rdm);
        print_ident(rdm, name);
        print_str(rdm, " = ", std.mem.len(" = "));
        demangle_type(rdm);
    }
    if (open != 0) {
        print_str(rdm, ">", std.mem.len(">"));
    }
}
pub fn demangle_const(arg_rdm: [*c]struct_rust_demangler) callconv(.C) void {
    var rdm = arg_rdm;
    var ty_tag: u8 = undefined;
    var old_next: usize = undefined;
    var backref: usize = undefined;
    if (rdm.*.errored != 0) return;
    if (eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, 'B')))) != 0) {
        backref = parse_integer_62(rdm);
        if (!(rdm.*.skipping_printing != 0)) {
            old_next = rdm.*.next;
            rdm.*.next = backref;
            demangle_const(rdm);
            rdm.*.next = old_next;
        }
        return;
    }
    ty_tag = next(rdm);
    while (true) {
        switch (@bitCast(c_int, @as(c_uint, ty_tag))) {
            @as(c_int, 104), @as(c_int, 116), @as(c_int, 109), @as(c_int, 121), @as(c_int, 111), @as(c_int, 106) => break,
            else => {
                rdm.*.errored = 1;
                return;
            },
        }
        break;
    }
    if (eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, 'p')))) != 0) {
        print_str(rdm, "_", std.mem.len("_"));
    } else {
        demangle_const_uint(rdm);
    }
    if (rdm.*.verbose != 0) {
        print_str(rdm, ": ", std.mem.len(": "));
        print_str(rdm, basic_type(ty_tag), std.mem.len(basic_type(ty_tag)));
    }
}
pub fn demangle_const_uint(arg_rdm: [*c]struct_rust_demangler) callconv(.C) void {
    var rdm = arg_rdm;
    var c: u8 = undefined;
    var hex_len: usize = undefined;
    var value: u64 = undefined;
    if (rdm.*.errored != 0) return;
    value = 0;
    hex_len = 0;
    while (!(eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, '_')))) != 0)) {
        value <<= @intCast(std.math.Log2Int(c_int), @as(c_int, 4));
        c = next(rdm);
        if ((@bitCast(c_int, @as(c_uint, c)) >= @as(c_int, '0')) and (@bitCast(c_int, @as(c_uint, c)) <= @as(c_int, '9'))) {
            value |= @bitCast(c_ulong, @as(c_long, @bitCast(c_int, @as(c_uint, c)) - @as(c_int, '0')));
        } else if ((@bitCast(c_int, @as(c_uint, c)) >= @as(c_int, 'a')) and (@bitCast(c_int, @as(c_uint, c)) <= @as(c_int, 'f'))) {
            value |= @bitCast(c_ulong, @as(c_long, @as(c_int, 10) + (@bitCast(c_int, @as(c_uint, c)) - @as(c_int, 'a'))));
        } else {
            rdm.*.errored = 1;
            return;
        }
        hex_len +%= 1;
    }
    if (hex_len > @bitCast(c_ulong, @as(c_long, @as(c_int, 16)))) {
        print_str(rdm, "0x", std.mem.len("0x"));
        print_str(rdm, rdm.*.sym + (rdm.*.next -% hex_len), hex_len);
        return;
    }
    print_uint64(rdm, value);
}
pub fn basic_type(arg_tag: u8) callconv(.C) [*c]const u8 {
    var tag = arg_tag;
    while (true) {
        switch (@bitCast(c_int, @as(c_uint, tag))) {
            @as(c_int, 98) => return "bool",
            @as(c_int, 99) => return "char",
            @as(c_int, 101) => return "str",
            @as(c_int, 117) => return "()",
            @as(c_int, 97) => return "i8",
            @as(c_int, 115) => return "i16",
            @as(c_int, 108) => return "i32",
            @as(c_int, 120) => return "i64",
            @as(c_int, 110) => return "i128",
            @as(c_int, 105) => return "isize",
            @as(c_int, 104) => return "u8",
            @as(c_int, 116) => return "u16",
            @as(c_int, 109) => return "u32",
            @as(c_int, 121) => return "u64",
            @as(c_int, 111) => return "u128",
            @as(c_int, 106) => return "usize",
            @as(c_int, 102) => return "f32",
            @as(c_int, 100) => return "f64",
            @as(c_int, 122) => return "!",
            @as(c_int, 112) => return "_",
            @as(c_int, 118) => return "...",
            else => return null,
        }
        break;
    }
    return null;
}
pub fn is_legacy_prefixed_hash(arg_ident: struct_rust_mangled_ident) callconv(.C) c_int {
    var ident = arg_ident;
    var seen: u16 = undefined;
    var nibble: c_int = undefined;
    var i: usize = undefined;
    var count: usize = undefined;
    if ((ident.ascii_len != @bitCast(c_ulong, @as(c_long, @as(c_int, 17)))) or (@bitCast(c_int, @as(c_uint, ident.ascii[@intCast(c_uint, @as(c_int, 0))])) != @as(c_int, 'h'))) return 0;
    seen = 0;
    {
        i = 0;
        while (i < @bitCast(c_ulong, @as(c_long, @as(c_int, 16)))) : (i +%= 1) {
            nibble = decode_lower_hex_nibble(ident.ascii[@bitCast(c_ulong, @as(c_long, @as(c_int, 1))) +% i]);
            if (nibble < @as(c_int, 0)) return 0;
            seen |= @bitCast(u16, @truncate(c_short, @bitCast(c_int, @as(c_uint, @bitCast(u16, @truncate(c_short, @as(c_int, 1))))) << @intCast(std.math.Log2Int(c_int), nibble)));
        }
    }
    count = 0;
    while (seen != 0) {
        if ((@bitCast(c_int, @as(c_uint, seen)) & @as(c_int, 1)) != 0) {
            count +%= 1;
        }
        seen >>= @intCast(std.math.Log2Int(c_int), @as(c_int, 1));
    }
    return @boolToInt(count >= @bitCast(c_ulong, @as(c_long, @as(c_int, 5))));
}
pub export fn rust_demangle_callback(arg_mangled: [*c]const u8, arg_options: c_int, arg_callback: demangle_callbackref, arg_opaque: ?*anyopaque) c_int {
    var mangled = arg_mangled;
    var options = arg_options;
    var callback = arg_callback;
    var @"opaque" = arg_opaque;
    var p: [*c]const u8 = undefined;
    var rdm: struct_rust_demangler = undefined;
    var ident: struct_rust_mangled_ident = undefined;
    rdm.sym = mangled;
    rdm.sym_len = 0;
    rdm.callback_opaque = @"opaque";
    rdm.callback = callback;
    rdm.next = 0;
    rdm.errored = 0;
    rdm.skipping_printing = 0;
    rdm.verbose = @boolToInt((options & (@as(c_int, 1) << @intCast(std.math.Log2Int(c_int), 3))) != @as(c_int, 0));
    rdm.version = 0;
    rdm.bound_lifetime_depth = 0;
    if ((@bitCast(c_int, @as(c_uint, rdm.sym[@intCast(c_uint, @as(c_int, 0))])) == @as(c_int, '_')) and (@bitCast(c_int, @as(c_uint, rdm.sym[@intCast(c_uint, @as(c_int, 1))])) == @as(c_int, 'R'))) {
        rdm.sym += @bitCast(usize, @intCast(isize, @as(c_int, 2)));
    } else if (((@bitCast(c_int, @as(c_uint, rdm.sym[@intCast(c_uint, @as(c_int, 0))])) == @as(c_int, '_')) and (@bitCast(c_int, @as(c_uint, rdm.sym[@intCast(c_uint, @as(c_int, 1))])) == @as(c_int, 'Z'))) and (@bitCast(c_int, @as(c_uint, rdm.sym[@intCast(c_uint, @as(c_int, 2))])) == @as(c_int, 'N'))) {
        rdm.sym += @bitCast(usize, @intCast(isize, @as(c_int, 3)));
        rdm.version = -@as(c_int, 1);
    } else return 0;
    if ((rdm.version != -@as(c_int, 1)) and !((@bitCast(c_int, @as(c_uint, rdm.sym[@intCast(c_uint, @as(c_int, 0))])) >= @as(c_int, 'A')) and (@bitCast(c_int, @as(c_uint, rdm.sym[@intCast(c_uint, @as(c_int, 0))])) <= @as(c_int, 'Z')))) return 0;
    {
        p = rdm.sym;
        while (p.* != 0) : (p += 1) {
            rdm.sym_len +%= 1;
            if ((@bitCast(c_int, @as(c_uint, p.*)) == @as(c_int, '_')) or ((((@bitCast(c_int, @as(c_uint, p.*)) >= @as(c_int, '0')) and (@bitCast(c_int, @as(c_uint, p.*)) <= @as(c_int, '9'))) or ((@bitCast(c_int, @as(c_uint, p.*)) >= @as(c_int, 'a')) and (@bitCast(c_int, @as(c_uint, p.*)) <= @as(c_int, 'z')))) or ((@bitCast(c_int, @as(c_uint, p.*)) >= @as(c_int, 'A')) and (@bitCast(c_int, @as(c_uint, p.*)) <= @as(c_int, 'Z'))))) continue;
            if ((rdm.version == -@as(c_int, 1)) and (((@bitCast(c_int, @as(c_uint, p.*)) == @as(c_int, '$')) or (@bitCast(c_int, @as(c_uint, p.*)) == @as(c_int, '.'))) or (@bitCast(c_int, @as(c_uint, p.*)) == @as(c_int, ':')))) continue;
            return 0;
        }
    }
    if (rdm.version == -@as(c_int, 1)) {
        if (!((rdm.sym_len > @bitCast(c_ulong, @as(c_long, @as(c_int, 0)))) and (@bitCast(c_int, @as(c_uint, rdm.sym[rdm.sym_len -% @bitCast(c_ulong, @as(c_long, @as(c_int, 1)))])) == @as(c_int, 'E')))) return 0;
        rdm.sym_len -%= 1;
        if (!((rdm.sym_len > @bitCast(c_ulong, @as(c_long, @as(c_int, 19)))) and !(C.memcmp(@ptrCast(?*const anyopaque, &rdm.sym[rdm.sym_len -% @bitCast(c_ulong, @as(c_long, @as(c_int, 19)))]), @ptrCast(?*const anyopaque, "17h"), @bitCast(c_ulong, @as(c_long, @as(c_int, 3)))) != 0))) return 0;
        while (true) {
            ident = parse_ident(&rdm);
            if ((rdm.errored != 0) or !(ident.ascii != null)) return 0;
            if (!(rdm.next < rdm.sym_len)) break;
        }
        if (!(is_legacy_prefixed_hash(ident) != 0)) return 0;
        rdm.next = 0;
        if (!(rdm.verbose != 0) and (rdm.sym_len > @bitCast(c_ulong, @as(c_long, @as(c_int, 19))))) {
            rdm.sym_len -%= @bitCast(c_ulong, @as(c_long, @as(c_int, 19)));
        }
        while (true) {
            if (rdm.next > @bitCast(c_ulong, @as(c_long, @as(c_int, 0)))) {
                print_str(&rdm, "::", @bitCast(usize, @as(c_long, @as(c_int, 2))));
            }
            ident = parse_ident(&rdm);
            print_ident(&rdm, ident);
            if (!(rdm.next < rdm.sym_len)) break;
        }
    } else {
        demangle_path(&rdm, @as(c_int, 1));
        if (!(rdm.errored != 0) and (rdm.next < rdm.sym_len)) {
            rdm.skipping_printing = 1;
            demangle_path(&rdm, @as(c_int, 0));
        }
        rdm.errored = @boolToInt(rdm.next != rdm.sym_len);
    }
    return @boolToInt(!(rdm.errored != 0));
}
pub const struct_str_buf = extern struct {
    ptr: [*c]u8,
    len: usize,
    cap: usize,
    errored: c_int,
};
pub fn str_buf_reserve(arg_buf: [*c]struct_str_buf, arg_extra: usize) callconv(.C) void {
    var buf = arg_buf;
    var extra = arg_extra;
    var available: usize = undefined;
    var min_new_cap: usize = undefined;
    var new_cap: usize = undefined;
    var new_ptr: [*c]u8 = undefined;
    if (buf.*.errored != 0) return;
    available = buf.*.cap -% buf.*.len;
    if (extra <= available) return;
    min_new_cap = buf.*.cap +% (extra -% available);
    if (min_new_cap < buf.*.cap) {
        buf.*.errored = 1;
        return;
    }
    new_cap = buf.*.cap;
    if (new_cap == @bitCast(c_ulong, @as(c_long, @as(c_int, 0)))) {
        new_cap = 4;
    }
    while (new_cap < min_new_cap) {
        new_cap *%= @bitCast(c_ulong, @as(c_long, @as(c_int, 2)));
        if (new_cap < buf.*.cap) {
            buf.*.errored = 1;
            return;
        }
    }
    new_ptr = @ptrCast([*c]u8, @alignCast(std.meta.alignment([*c]u8), std.c.realloc(buf.*.ptr, new_cap)));
    if (new_ptr == @ptrCast([*c]u8, @alignCast(std.meta.alignment([*c]u8), @intToPtr(?*anyopaque, @as(c_int, 0))))) {
        std.c.free(buf.*.ptr);
        buf.*.ptr = null;
        buf.*.len = 0;
        buf.*.cap = 0;
        buf.*.errored = 1;
    } else {
        buf.*.ptr = new_ptr;
        buf.*.cap = new_cap;
    }
}
pub fn str_buf_append(arg_buf: [*c]struct_str_buf, arg_data: [*c]const u8, arg_len: usize) callconv(.C) void {
    var buf = arg_buf;
    var data = arg_data;
    var len = arg_len;
    str_buf_reserve(buf, len);
    if (buf.*.errored != 0) return;
    _ = C.memcpy(@ptrCast(?*anyopaque, buf.*.ptr + buf.*.len), @ptrCast(?*const anyopaque, data), len);
    buf.*.len +%= len;
}
pub fn str_buf_demangle_callback(arg_data: [*c]const u8, arg_len: usize, arg_opaque: ?*anyopaque) callconv(.C) void {
    var data = arg_data;
    var len = arg_len;
    var @"opaque" = arg_opaque;
    str_buf_append(@ptrCast([*c]struct_str_buf, @alignCast(std.meta.alignment([*c]struct_str_buf), @"opaque")), data, len);
}
pub export fn rust_demangle(arg_mangled: [*c]const u8, arg_options: c_int) [*c]u8 {
    var mangled = arg_mangled;
    var options = arg_options;
    var out: struct_str_buf = undefined;
    var success: c_int = undefined;
    out.ptr = null;
    out.len = 0;
    out.cap = 0;
    out.errored = 0;
    success = rust_demangle_callback(mangled, options, &str_buf_demangle_callback, @ptrCast(?*anyopaque, &out));
    if (!(success != 0)) {
        std.c.free(out.ptr);
        return null;
    }
    str_buf_append(&out, "\x00", @bitCast(usize, @as(c_long, @as(c_int, 1))));
    return out.ptr;
}

pub const rust_demangler = struct_rust_demangler;
pub const rust_mangled_ident = struct_rust_mangled_ident;
pub const str_buf = struct_str_buf;
