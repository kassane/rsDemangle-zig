// const demangle = @import("demangle.zig"); // WIP

// pub const demangle_callbackref = ?fn ([*c]const u8, c_int, ?*anyopaque) callconv(.C) void;
// pub extern fn rust_demangle_callback(mangled: [*c]const u8, options: c_int, callback: demangle_callbackref, @"opaque": ?*anyopaque) c_int;
pub extern fn rust_demangle(mangled: [*:0]const u8, options: c_int) [*:0]const u8;

pub fn main() void {
    const print = @import("std").debug.print;

    const verbose = false;
    const options: c_int = (1 << 8) | switch (verbose) {
        true => (1 << 3),
        false => 0,
    };

    const demangled = rust_demangle("_ZN11rust_mangle7sum_add17hf6faed35db54da66E", options);
    print("Rust demangle:\n{s}\n", .{demangled});
}

test "demangled" {
    var verbose = false;
    const options: c_int = (1 << 8) | switch (verbose) {
        true => @as(c_int, 1 << 3),
        false => 0,
    };

    const expected = @import("std").testing.expectEqualStrings;
    // _ = expected.expectEqualSlices(comptime T: type, expected: []const T, actual: []const T)
    expected(rust_demangle("_ZN11rust_mangle7sum_add17hf6faed35db54da66E", options), "rust_mangle::sum_add"); // No verbose
    verbose = true;
    expected(rust_demangle("_ZN11rust_mangle7sum_add17hf6faed35db54da66E", options), "rust_mangle::sum_add::hf6faed35db54da66"); //Verbose

    expected(rust_demangle("_RNCINkXs25_NgCsbmNqQUJIY6D_4core5sliceINyB9_4IterhENuNgNoBb_4iter8iterator8Iterator9rpositionNCNgNpB9_6memchr7memrchrs_0E0Bb_"), "<core::slice::Iter<u8> as core::iter::iterator::Iterator>::rposition::<core::slice::memchr::memrchr::{closure#1}>::{closure#0}");
    expected(rust_demangle("_RINbNbCskIICzLVDPPb_5alloc5alloc8box_freeDINbNiB4_5boxed5FnBoxuEp6OutputuEL_ECs1iopQbuBiw2_3std"), "alloc::alloc::box_free::<dyn alloc::boxed::FnBox<(), Output = ()>>");
}
