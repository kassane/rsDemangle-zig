const std = @import("std");
const testing = std.testing;
const mem = std.mem;
const demangle = @import("demangle.zig"); // WIP

pub fn main() void {
    const print = std.debug.print;

    const verbose = false;
    const options: c_int = (1 << 8) | switch (verbose) {
        true => (1 << 3),
        false => 0,
    };

    const demangled = demangle.rust_demangle("_ZN11rust_mangle7sum_add17hf6faed35db54da66E", options);
    print("Rust demangle:\n{s}\n", .{demangled});
}

test "demangled" {
    var verbose = false;
    var options: c_int = (1 << 8) | switch (verbose) {
        true => @as(c_int, 1 << 3),
        false => 0,
    };

    var demangled = mem.sliceTo(demangle.rust_demangle("_ZN11rust_mangle7sum_add17hf6faed35db54da66E", options), 0);

    const expected = testing.expect;
    try expected(mem.eql(u8, demangled, "rust_mangle::sum_add")); // No verbose

    verbose = true;
    options = (1 << 8) | switch (verbose) {
        true => @as(c_int, 1 << 3),
        false => 0,
    };
    demangled = mem.sliceTo(demangle.rust_demangle("_ZN11rust_mangle7sum_add17hf6faed35db54da66E", options), 0);
    try expected(mem.eql(u8, demangled, "rust_mangle::sum_add::hf6faed35db54da66")); //Verbose

    verbose = false;
    options = (1 << 8) | switch (verbose) {
        true => @as(c_int, 1 << 3),
        false => 0,
    };
    demangled = mem.sliceTo(demangle.rust_demangle("_RNCINkXs25_NgCsbmNqQUJIY6D_4core5sliceINyB9_4IterhENuNgNoBb_4iter8iterator8Iterator9rpositionNCNgNpB9_6memchr7memrchrs_0E0Bb_", options), 0);
    try expected(mem.eql(u8, demangled, "<core::slice::Iter<u8> as core::iter::iterator::Iterator>::rposition::<core::slice::memchr::memrchr::{closure#1}>::{closure#0}"));

    demangled = mem.sliceTo(demangle.rust_demangle("_RINbNbCskIICzLVDPPb_5alloc5alloc8box_freeDINbNiB4_5boxed5FnBoxuEp6OutputuEL_ECs1iopQbuBiw2_3std", options), 0);
    try expected(mem.eql(u8, demangled, "alloc::alloc::box_free::<dyn alloc::boxed::FnBox<(), Output = ()>>"));
}
