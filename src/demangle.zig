// translate-c - zig stage2

const strlen = @import("std").mem.len;
const sprintf = @cImport(@cInclude("stdio.h")).sprintf; //libc
const free = @cImport(@cInclude("stdlib.h")).free; //libc
const memcpy = @cImport(@cInclude("string.h")).memcpy; //libc
const realloc = @cImport(@cInclude("stdlib.h")).realloc; //libc

pub const rust_demangler = extern struct {
    sym: [*c]const u8,
    sym_len: usize,
    callback_opaque: ?*anyopaque,
    callback: ?*const fn ([*c]const u8, usize, ?*anyopaque) callconv(.C) void,
    next: usize,
    errored: bool,
    skipping_printing: bool,
    verbose: bool,
    version: c_int,
    bound_lifetime_depth: u64,
};
pub fn peek(arg_rdm: [*c]const rust_demangler) callconv(.C) u8 {
    var rdm = arg_rdm;
    if (rdm.*.next < rdm.*.sym_len) return rdm.*.sym[rdm.*.next];
    return 0;
}
pub fn eat(arg_rdm: [*c]rust_demangler, arg_c: u8) callconv(.C) bool {
    var rdm = arg_rdm;
    var c = arg_c;
    if (@bitCast(c_int, @as(c_uint, peek(rdm))) == @bitCast(c_int, @as(c_uint, c))) {
        rdm.*.next +%= 1;
        return @as(c_int, 1) != 0;
    } else return @as(c_int, 0) != 0;
    return false;
}
pub fn next(arg_rdm: [*c]rust_demangler) callconv(.C) u8 {
    var rdm = arg_rdm;
    var c: u8 = peek(rdm);
    {
        if (!(c != 0)) {
            rdm.*.errored = @as(c_int, 1) != 0;
            return 0;
        }
    }
    rdm.*.next +%= 1;
    return c;
}
pub fn parse_integer_62(arg_rdm: [*c]rust_demangler) callconv(.C) u64 {
    var rdm = arg_rdm;
    if (eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, '_'))))) return 0;
    var x: u64 = 0;
    while (!eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, '_'))))) {
        var c: u8 = next(rdm);
        x *%= @bitCast(c_ulong, @as(c_long, @as(c_int, 62)));
        if ((@bitCast(c_int, @as(c_uint, c)) >= @as(c_int, '0')) and (@bitCast(c_int, @as(c_uint, c)) <= @as(c_int, '9'))) {
            x +%= @bitCast(c_ulong, @as(c_long, @bitCast(c_int, @as(c_uint, c)) - @as(c_int, '0')));
        } else if ((@bitCast(c_int, @as(c_uint, c)) >= @as(c_int, 'a')) and (@bitCast(c_int, @as(c_uint, c)) <= @as(c_int, 'z'))) {
            x +%= @bitCast(c_ulong, @as(c_long, @as(c_int, 10) + (@bitCast(c_int, @as(c_uint, c)) - @as(c_int, 'a'))));
        } else if ((@bitCast(c_int, @as(c_uint, c)) >= @as(c_int, 'A')) and (@bitCast(c_int, @as(c_uint, c)) <= @as(c_int, 'Z'))) {
            x +%= @bitCast(c_ulong, @as(c_long, (@as(c_int, 10) + @as(c_int, 26)) + (@bitCast(c_int, @as(c_uint, c)) - @as(c_int, 'A'))));
        } else {
            rdm.*.errored = @as(c_int, 1) != 0;
            return 0;
        }
    }
    return x +% @bitCast(c_ulong, @as(c_long, @as(c_int, 1)));
}
pub fn parse_opt_integer_62(arg_rdm: [*c]rust_demangler, arg_tag: u8) callconv(.C) u64 {
    var rdm = arg_rdm;
    var tag = arg_tag;
    if (!eat(rdm, tag)) return 0;
    return @bitCast(c_ulong, @as(c_long, @as(c_int, 1))) +% parse_integer_62(rdm);
}
pub fn parse_disambiguator(arg_rdm: [*c]rust_demangler) callconv(.C) u64 {
    var rdm = arg_rdm;
    return parse_opt_integer_62(rdm, @bitCast(u8, @truncate(i8, @as(c_int, 's'))));
}
pub const rust_mangled_ident = extern struct {
    ascii: [*c]const u8,
    ascii_len: usize,
    punycode: [*c]const u8,
    punycode_len: usize,
};
pub fn parse_ident(arg_rdm: [*c]rust_demangler) callconv(.C) rust_mangled_ident {
    var rdm = arg_rdm;
    var ident: rust_mangled_ident = undefined;
    ident.ascii = null;
    ident.ascii_len = 0;
    ident.punycode = null;
    ident.punycode_len = 0;
    var is_punycode: bool = eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, 'u'))));
    var c: u8 = next(rdm);
    {
        if (!((@bitCast(c_int, @as(c_uint, c)) >= @as(c_int, '0')) and (@bitCast(c_int, @as(c_uint, c)) <= @as(c_int, '9')))) {
            rdm.*.errored = @as(c_int, 1) != 0;
            return ident;
        }
    }
    var len: usize = @bitCast(usize, @as(c_long, @bitCast(c_int, @as(c_uint, c)) - @as(c_int, '0')));
    if (@bitCast(c_int, @as(c_uint, c)) != @as(c_int, '0')) while ((@bitCast(c_int, @as(c_uint, peek(rdm))) >= @as(c_int, '0')) and (@bitCast(c_int, @as(c_uint, peek(rdm))) <= @as(c_int, '9'))) {
        len = (len *% @bitCast(c_ulong, @as(c_long, @as(c_int, 10)))) +% @bitCast(c_ulong, @as(c_long, @bitCast(c_int, @as(c_uint, next(rdm))) - @as(c_int, '0')));
    };
    _ = eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, '_'))));
    var start: usize = rdm.*.next;
    rdm.*.next +%= len;
    {
        if (!((start <= rdm.*.next) and (rdm.*.next <= rdm.*.sym_len))) {
            rdm.*.errored = @as(c_int, 1) != 0;
            return ident;
        }
    }
    ident.ascii = rdm.*.sym + start;
    ident.ascii_len = len;
    if (is_punycode) {
        ident.punycode_len = 0;
        while (ident.ascii_len > @bitCast(c_ulong, @as(c_long, @as(c_int, 0)))) {
            ident.ascii_len -%= 1;
            if (@bitCast(c_int, @as(c_uint, ident.ascii[ident.ascii_len])) == @as(c_int, '_')) break;
            ident.punycode_len +%= 1;
        }
        {
            if (!(ident.punycode_len > @bitCast(c_ulong, @as(c_long, @as(c_int, 0))))) {
                rdm.*.errored = @as(c_int, 1) != 0;
                return ident;
            }
        }
        ident.punycode = ident.ascii + (len -% ident.punycode_len);
    }
    if (ident.ascii_len == @bitCast(c_ulong, @as(c_long, @as(c_int, 0)))) {
        ident.ascii = null;
    }
    return ident;
}
pub fn print_str(arg_rdm: [*c]rust_demangler, arg_data: [*c]const u8, arg_len: usize) callconv(.C) void {
    var rdm = arg_rdm;
    var data = arg_data;
    var len = arg_len;
    if (!rdm.*.errored and !rdm.*.skipping_printing) {
        rdm.*.callback.?(data, len, rdm.*.callback_opaque);
    }
}
pub fn print_uint64(arg_rdm: [*c]rust_demangler, arg_x: u64) callconv(.C) void {
    var rdm = arg_rdm;
    var x = arg_x;
    var s: [21]u8 = undefined;
    _ = sprintf(@ptrCast([*c]u8, @alignCast(@import("std").meta.alignment(u8), &s)), "%lu", x);
    print_str(rdm, @ptrCast([*c]u8, @alignCast(@import("std").meta.alignment(u8), &s)), strlen(@ptrCast([*c]u8, @alignCast(@import("std").meta.alignment(u8), &s))));
}
pub fn print_uint64_hex(arg_rdm: [*c]rust_demangler, arg_x: u64) callconv(.C) void {
    var rdm = arg_rdm;
    var x = arg_x;
    var s: [17]u8 = undefined;
    _ = sprintf(@ptrCast([*c]u8, @alignCast(@import("std").meta.alignment(u8), &s)), "%lx", x);
    print_str(rdm, @ptrCast([*c]u8, @alignCast(@import("std").meta.alignment(u8), &s)), strlen(@ptrCast([*c]u8, @alignCast(@import("std").meta.alignment(u8), &s))));
} // src/rust-demangle.c:244:51: warning: TODO implement translation of stmt class GotoStmtClass
// src/rust-demangle.c:187:13: warning: unable to translate function, demoted to extern
pub extern fn print_ident(arg_rdm: [*c]rust_demangler, arg_ident: rust_mangled_ident) callconv(.C) void;
pub fn print_lifetime_from_index(arg_rdm: [*c]rust_demangler, arg_lt: u64) callconv(.C) void {
    var rdm = arg_rdm;
    var lt = arg_lt;
    print_str(rdm, "'", strlen("'"));
    if (lt == @bitCast(c_ulong, @as(c_long, @as(c_int, 0)))) {
        print_str(rdm, "_", strlen("_"));
        return;
    }
    var depth: u64 = rdm.*.bound_lifetime_depth -% lt;
    if (depth < @bitCast(c_ulong, @as(c_long, @as(c_int, 26)))) {
        var c: u8 = @bitCast(u8, @truncate(u8, @bitCast(c_ulong, @as(c_long, @as(c_int, 'a'))) +% depth));
        print_str(rdm, &c, @bitCast(usize, @as(c_long, @as(c_int, 1))));
    } else {
        print_str(rdm, "_", strlen("_"));
        print_uint64(rdm, depth);
    }
}
pub fn demangle_binder(arg_rdm: [*c]rust_demangler) callconv(.C) void {
    var rdm = arg_rdm;
    {
        if (!!rdm.*.errored) {
            rdm.*.errored = @as(c_int, 1) != 0;
            return;
        }
    }
    var bound_lifetimes: u64 = parse_opt_integer_62(rdm, @bitCast(u8, @truncate(i8, @as(c_int, 'G'))));
    if (bound_lifetimes > @bitCast(c_ulong, @as(c_long, @as(c_int, 0)))) {
        print_str(rdm, "for<", strlen("for<"));
        {
            var i: u64 = 0;
            while (i < bound_lifetimes) : (i +%= 1) {
                if (i > @bitCast(c_ulong, @as(c_long, @as(c_int, 0)))) {
                    print_str(rdm, ", ", strlen(", "));
                }
                rdm.*.bound_lifetime_depth +%= 1;
                print_lifetime_from_index(rdm, @bitCast(u64, @as(c_long, @as(c_int, 1))));
            }
        }
        print_str(rdm, "> ", strlen("> "));
    }
}
pub fn demangle_path(arg_rdm: [*c]rust_demangler, arg_in_value: bool) callconv(.C) void {
    var rdm = arg_rdm;
    var in_value = arg_in_value;
    {
        if (!!rdm.*.errored) {
            rdm.*.errored = @as(c_int, 1) != 0;
            return;
        }
    }
    var tag: u8 = next(rdm);
    while (true) {
        switch (@bitCast(c_int, @as(c_uint, tag))) {
            @as(c_int, 67) => {
                {
                    var dis: u64 = parse_disambiguator(rdm);
                    var name: rust_mangled_ident = parse_ident(rdm);
                    print_ident(rdm, name);
                    if (rdm.*.verbose) {
                        print_str(rdm, "[", strlen("["));
                        print_uint64_hex(rdm, dis);
                        print_str(rdm, "]", strlen("]"));
                    }
                    break;
                }
            },
            @as(c_int, 78) => {
                {
                    var ns: u8 = next(rdm);
                    {
                        if (!(((@bitCast(c_int, @as(c_uint, ns)) >= @as(c_int, 'a')) and (@bitCast(c_int, @as(c_uint, ns)) <= @as(c_int, 'z'))) or ((@bitCast(c_int, @as(c_uint, ns)) >= @as(c_int, 'A')) and (@bitCast(c_int, @as(c_uint, ns)) <= @as(c_int, 'Z'))))) {
                            rdm.*.errored = @as(c_int, 1) != 0;
                            return;
                        }
                    }
                    demangle_path(rdm, in_value);
                    var dis: u64 = parse_disambiguator(rdm);
                    var name: rust_mangled_ident = parse_ident(rdm);
                    if ((@bitCast(c_int, @as(c_uint, ns)) >= @as(c_int, 'A')) and (@bitCast(c_int, @as(c_uint, ns)) <= @as(c_int, 'Z'))) {
                        print_str(rdm, "::{", strlen("::{"));
                        while (true) {
                            switch (@bitCast(c_int, @as(c_uint, ns))) {
                                @as(c_int, 67) => {
                                    print_str(rdm, "closure", strlen("closure"));
                                    break;
                                },
                                @as(c_int, 83) => {
                                    print_str(rdm, "shim", strlen("shim"));
                                    break;
                                },
                                else => {
                                    print_str(rdm, &ns, @bitCast(usize, @as(c_long, @as(c_int, 1))));
                                },
                            }
                            break;
                        }
                        if ((name.ascii != null) or (name.punycode != null)) {
                            print_str(rdm, ":", strlen(":"));
                            print_ident(rdm, name);
                        }
                        print_str(rdm, "#", strlen("#"));
                        print_uint64(rdm, dis);
                        print_str(rdm, "}", strlen("}"));
                    } else {
                        if ((name.ascii != null) or (name.punycode != null)) {
                            print_str(rdm, "::", strlen("::"));
                            print_ident(rdm, name);
                        }
                    }
                    break;
                }
            },
            @as(c_int, 77), @as(c_int, 88) => {
                _ = parse_disambiguator(rdm);
                var was_skipping_printing: bool = rdm.*.skipping_printing;
                rdm.*.skipping_printing = @as(c_int, 1) != 0;
                demangle_path(rdm, in_value);
                rdm.*.skipping_printing = was_skipping_printing;
                print_str(rdm, "<", strlen("<"));
                demangle_type(rdm);
                if (@bitCast(c_int, @as(c_uint, tag)) != @as(c_int, 'M')) {
                    print_str(rdm, " as ", strlen(" as "));
                    demangle_path(rdm, @as(c_int, 0) != 0);
                }
                print_str(rdm, ">", strlen(">"));
                break;
            },
            @as(c_int, 89) => {
                print_str(rdm, "<", strlen("<"));
                demangle_type(rdm);
                if (@bitCast(c_int, @as(c_uint, tag)) != @as(c_int, 'M')) {
                    print_str(rdm, " as ", strlen(" as "));
                    demangle_path(rdm, @as(c_int, 0) != 0);
                }
                print_str(rdm, ">", strlen(">"));
                break;
            },
            @as(c_int, 73) => {
                demangle_path(rdm, in_value);
                if (in_value) {
                    print_str(rdm, "::", strlen("::"));
                }
                print_str(rdm, "<", strlen("<"));
                {
                    var i: usize = 0;
                    while (!rdm.*.errored and !eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, 'E'))))) : (i +%= 1) {
                        if (i > @bitCast(c_ulong, @as(c_long, @as(c_int, 0)))) {
                            print_str(rdm, ", ", strlen(", "));
                        }
                        demangle_generic_arg(rdm);
                    }
                }
                print_str(rdm, ">", strlen(">"));
                break;
            },
            @as(c_int, 66) => {
                {
                    var backref: usize = parse_integer_62(rdm);
                    if (!rdm.*.skipping_printing) {
                        var old_next: usize = rdm.*.next;
                        rdm.*.next = backref;
                        demangle_path(rdm, in_value);
                        rdm.*.next = old_next;
                    }
                    break;
                }
            },
            else => {
                {
                    rdm.*.errored = @as(c_int, 1) != 0;
                    return;
                }
            },
        }
        break;
    }
}
pub fn demangle_generic_arg(arg_rdm: [*c]rust_demangler) callconv(.C) void {
    var rdm = arg_rdm;
    if (eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, 'L'))))) {
        var lt: u64 = parse_integer_62(rdm);
        print_lifetime_from_index(rdm, lt);
    } else if (eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, 'K'))))) {
        demangle_const(rdm);
    } else {
        demangle_type(rdm);
    }
} // src/rust-demangle.c:600:46: warning: TODO implement translation of stmt class GotoStmtClass
// src/rust-demangle.c:528:13: warning: unable to translate function, demoted to extern
pub extern fn demangle_type(arg_rdm: [*c]rust_demangler) callconv(.C) void;
pub fn demangle_path_maybe_open_generics(arg_rdm: [*c]rust_demangler) callconv(.C) bool {
    var rdm = arg_rdm;
    var open: bool = @as(c_int, 0) != 0;
    {
        if (!!rdm.*.errored) {
            rdm.*.errored = @as(c_int, 1) != 0;
            return open;
        }
    }
    if (eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, 'B'))))) {
        var backref: usize = parse_integer_62(rdm);
        if (!rdm.*.skipping_printing) {
            var old_next: usize = rdm.*.next;
            rdm.*.next = backref;
            open = demangle_path_maybe_open_generics(rdm);
            rdm.*.next = old_next;
        }
    } else if (eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, 'I'))))) {
        demangle_path(rdm, @as(c_int, 0) != 0);
        print_str(rdm, "<", strlen("<"));
        open = @as(c_int, 1) != 0;
        {
            var i: usize = 0;
            while (!rdm.*.errored and !eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, 'E'))))) : (i +%= 1) {
                if (i > @bitCast(c_ulong, @as(c_long, @as(c_int, 0)))) {
                    print_str(rdm, ", ", strlen(", "));
                }
                demangle_generic_arg(rdm);
            }
        }
    } else {
        demangle_path(rdm, @as(c_int, 0) != 0);
    }
    return open;
}
pub fn demangle_dyn_trait(arg_rdm: [*c]rust_demangler) callconv(.C) void {
    var rdm = arg_rdm;
    {
        if (!!rdm.*.errored) {
            rdm.*.errored = @as(c_int, 1) != 0;
            return;
        }
    }
    var open: bool = demangle_path_maybe_open_generics(rdm);
    while (eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, 'p'))))) {
        if (!open) {
            print_str(rdm, "<", strlen("<"));
        } else {
            print_str(rdm, ", ", strlen(", "));
        }
        open = @as(c_int, 1) != 0;
        var name: rust_mangled_ident = parse_ident(rdm);
        print_ident(rdm, name);
        print_str(rdm, " = ", strlen(" = "));
        demangle_type(rdm);
    }
    if (open) {
        print_str(rdm, ">", strlen(">"));
    }
}
pub fn demangle_const(arg_rdm: [*c]rust_demangler) callconv(.C) void {
    var rdm = arg_rdm;
    {
        if (!!rdm.*.errored) {
            rdm.*.errored = @as(c_int, 1) != 0;
            return;
        }
    }
    if (eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, 'B'))))) {
        var backref: usize = parse_integer_62(rdm);
        if (!rdm.*.skipping_printing) {
            var old_next: usize = rdm.*.next;
            rdm.*.next = backref;
            demangle_const(rdm);
            rdm.*.next = old_next;
        }
        return;
    }
    var ty_tag: u8 = next(rdm);
    while (true) {
        switch (@bitCast(c_int, @as(c_uint, ty_tag))) {
            @as(c_int, 104), @as(c_int, 116), @as(c_int, 109), @as(c_int, 121), @as(c_int, 111), @as(c_int, 106) => break,
            else => {
                {
                    rdm.*.errored = @as(c_int, 1) != 0;
                    return;
                }
            },
        }
        break;
    }
    if (eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, 'p'))))) {
        print_str(rdm, "_", strlen("_"));
    } else {
        demangle_const_uint(rdm);
        if (rdm.*.verbose) {
            print_str(rdm, basic_type(ty_tag), strlen(basic_type(ty_tag)));
        }
    }
}
pub fn demangle_const_uint(arg_rdm: [*c]rust_demangler) callconv(.C) void {
    var rdm = arg_rdm;
    {
        if (!!rdm.*.errored) {
            rdm.*.errored = @as(c_int, 1) != 0;
            return;
        }
    }
    var value: u64 = 0;
    var hex_len: usize = 0;
    while (!eat(rdm, @bitCast(u8, @truncate(i8, @as(c_int, '_'))))) {
        value <<= @intCast(@import("std").math.Log2Int(c_int), @as(c_int, 4));
        var c: u8 = next(rdm);
        if ((@bitCast(c_int, @as(c_uint, c)) >= @as(c_int, '0')) and (@bitCast(c_int, @as(c_uint, c)) <= @as(c_int, '9'))) {
            value |= @bitCast(c_ulong, @as(c_long, @bitCast(c_int, @as(c_uint, c)) - @as(c_int, '0')));
        } else if ((@bitCast(c_int, @as(c_uint, c)) >= @as(c_int, 'a')) and (@bitCast(c_int, @as(c_uint, c)) <= @as(c_int, 'f'))) {
            value |= @bitCast(c_ulong, @as(c_long, @as(c_int, 10) + (@bitCast(c_int, @as(c_uint, c)) - @as(c_int, 'a'))));
        } else {
            rdm.*.errored = @as(c_int, 1) != 0;
            return;
        }
        hex_len +%= 1;
    }
    if (hex_len > @bitCast(c_ulong, @as(c_long, @as(c_int, 16)))) {
        print_str(rdm, "0x", strlen("0x"));
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
pub export fn rust_demangle_with_callback(arg_mangled: [*c]const u8, arg_flags: c_int, arg_callback: ?*const fn ([*c]const u8, usize, ?*anyopaque) callconv(.C) void, arg_opaque: ?*anyopaque) bool {
    var mangled = arg_mangled;
    var flags = arg_flags;
    var callback = arg_callback;
    var @"opaque" = arg_opaque;
    if ((@bitCast(c_int, @as(c_uint, mangled[@intCast(c_uint, @as(c_int, 0))])) == @as(c_int, '_')) and (@bitCast(c_int, @as(c_uint, mangled[@intCast(c_uint, @as(c_int, 1))])) == @as(c_int, 'R'))) {
        mangled += @bitCast(usize, @intCast(isize, @as(c_int, 2)));
    } else return @as(c_int, 0) != 0;
    if (!((@bitCast(c_int, @as(c_uint, mangled[@intCast(c_uint, @as(c_int, 0))])) >= @as(c_int, 'A')) and (@bitCast(c_int, @as(c_uint, mangled[@intCast(c_uint, @as(c_int, 0))])) <= @as(c_int, 'Z')))) return @as(c_int, 0) != 0;
    var rdm: rust_demangler = undefined;
    rdm.sym = mangled;
    rdm.sym_len = 0;
    rdm.callback_opaque = @"opaque";
    rdm.callback = callback;
    rdm.next = 0;
    rdm.errored = @as(c_int, 0) != 0;
    rdm.skipping_printing = @as(c_int, 0) != 0;
    rdm.verbose = (flags & @as(c_int, 1)) != @as(c_int, 0);
    rdm.version = 0;
    rdm.bound_lifetime_depth = 0;
    {
        var p: [*c]const u8 = mangled;
        while (p.* != 0) : (p += 1) {
            if (!((((@bitCast(c_int, @as(c_uint, p.*)) == @as(c_int, '_')) or ((@bitCast(c_int, @as(c_uint, p.*)) >= @as(c_int, '0')) and (@bitCast(c_int, @as(c_uint, p.*)) <= @as(c_int, '9')))) or ((@bitCast(c_int, @as(c_uint, p.*)) >= @as(c_int, 'a')) and (@bitCast(c_int, @as(c_uint, p.*)) <= @as(c_int, 'z')))) or ((@bitCast(c_int, @as(c_uint, p.*)) >= @as(c_int, 'A')) and (@bitCast(c_int, @as(c_uint, p.*)) <= @as(c_int, 'Z'))))) return @as(c_int, 0) != 0;
            rdm.sym_len +%= 1;
        }
    }
    demangle_path(&rdm, @as(c_int, 1) != 0);
    if (!rdm.errored and (rdm.next < rdm.sym_len)) {
        rdm.skipping_printing = @as(c_int, 1) != 0;
        demangle_path(&rdm, @as(c_int, 0) != 0);
    }
    rdm.errored = rdm.next != rdm.sym_len;
    return !rdm.errored;
}
pub const str_buf = extern struct {
    ptr: [*c]u8,
    len: usize,
    cap: usize,
    errored: bool,
};
pub fn str_buf_reserve(arg_buf: [*c]str_buf, arg_extra: usize) callconv(.C) void {
    var buf = arg_buf;
    var extra = arg_extra;
    if (buf.*.errored) return;
    var available: usize = buf.*.cap -% buf.*.len;
    if (extra <= available) return;
    var min_new_cap: usize = buf.*.cap +% (extra -% available);
    if (min_new_cap < buf.*.cap) {
        buf.*.errored = @as(c_int, 1) != 0;
        return;
    }
    var new_cap: usize = buf.*.cap;
    if (new_cap == @bitCast(c_ulong, @as(c_long, @as(c_int, 0)))) {
        new_cap = 4;
    }
    while (new_cap < min_new_cap) {
        new_cap *%= @bitCast(c_ulong, @as(c_long, @as(c_int, 2)));
        if (new_cap < buf.*.cap) {
            buf.*.errored = @as(c_int, 1) != 0;
            return;
        }
    }
    var new_ptr: [*c]u8 = @ptrCast([*c]u8, @alignCast(@import("std").meta.alignment(u8), realloc(@ptrCast(?*anyopaque, buf.*.ptr), new_cap)));
    if (new_ptr == @ptrCast([*c]u8, @alignCast(@import("std").meta.alignment(u8), @intToPtr(?*anyopaque, @as(c_int, 0))))) {
        free(@ptrCast(?*anyopaque, buf.*.ptr));
        buf.*.ptr = null;
        buf.*.len = 0;
        buf.*.cap = 0;
        buf.*.errored = @as(c_int, 1) != 0;
    } else {
        buf.*.ptr = new_ptr;
        buf.*.cap = new_cap;
    }
}
pub fn str_buf_append(arg_buf: [*c]str_buf, arg_data: [*c]const u8, arg_len: usize) callconv(.C) void {
    var buf = arg_buf;
    var data = arg_data;
    var len = arg_len;
    str_buf_reserve(buf, len);
    if (buf.*.errored) return;
    _ = memcpy(@ptrCast(?*anyopaque, buf.*.ptr + buf.*.len), @ptrCast(?*const anyopaque, data), len);
    buf.*.len +%= len;
}
pub fn str_buf_demangle_callback(arg_data: [*c]const u8, arg_len: usize, arg_opaque: ?*anyopaque) callconv(.C) void {
    var data = arg_data;
    var len = arg_len;
    var @"opaque" = arg_opaque;
    str_buf_append(@ptrCast([*c]str_buf, @alignCast(@import("std").meta.alignment(str_buf), @"opaque")), data, len);
}
pub export fn rust_demangle(arg_mangled: [*c]const u8, arg_flags: c_int) [*c]u8 {
    var mangled = arg_mangled;
    var flags = arg_flags;
    var out: str_buf = undefined;
    out.ptr = null;
    out.len = 0;
    out.cap = 0;
    out.errored = @as(c_int, 0) != 0;
    var success: bool = rust_demangle_with_callback(mangled, flags, str_buf_demangle_callback, @ptrCast(?*anyopaque, &out));
    if (!success) {
        free(@ptrCast(?*anyopaque, out.ptr));
        return null;
    }
    str_buf_append(&out, "\x00", @bitCast(usize, @as(c_long, @as(c_int, 1))));
    return out.ptr;
}
