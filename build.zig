const std = @import("std");


pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{
        .whitelist = espressif_targets,
        .default_target = espressif_targets[0],
    });
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "app_zig",
        .root_source_file = b.path("main/app.zig"),
        .target = target,
        .optimize = optimize,
    });


    const zig_idf_dep = b.dependency("zig_idf", .{
        .target = target,
        .optimize = optimize,
    });
    lib.root_module.addImport("zig_idf", zig_idf_dep.module("zig_idf"));

    lib.linkLibC(); // stubs for libc

    b.installArtifact(lib);
}

// Targets config
pub const espressif_targets: []const std.Target.Query = if (isEspXtensa())
    xtensa_targets ++ riscv_targets
else
    riscv_targets;

const riscv_targets = &[_]std.Target.Query{
    // esp32-c3/c2
    .{
        .cpu_arch = .riscv32,
        .cpu_model = .{ .explicit = &std.Target.riscv.cpu.generic_rv32 },
        .os_tag = .freestanding,
        .abi = .none,
        .cpu_features_add = std.Target.riscv.featureSet(&.{ .m, .c, .zifencei, .zicsr }),
    },
    // esp32-c6/61/h2
    .{
        .cpu_arch = .riscv32,
        .cpu_model = .{ .explicit = &std.Target.riscv.cpu.generic_rv32 },
        .os_tag = .freestanding,
        .abi = .none,
        .cpu_features_add = std.Target.riscv.featureSet(&.{ .m, .a, .c, .zifencei, .zicsr }),
    },
    // esp32-p4 have .xesppie cpu-feature (espressif vendor extension)
    .{
        .cpu_arch = .riscv32,
        .cpu_model = .{ .explicit = &std.Target.riscv.cpu.esp32p4 },
        .os_tag = .freestanding,
        .abi = .eabihf,
        .cpu_features_sub = std.Target.riscv.featureSet(&.{ .zca, .zcb, .zcmt, .zcmp }),
    },
};
const xtensa_targets = &[_]std.Target.Query{
    // need zig-fork (using espressif-llvm backend) to support this
    .{
        .cpu_arch = .xtensa,
        .cpu_model = .{ .explicit = &std.Target.xtensa.cpu.esp32 },
        .os_tag = .freestanding,
        .abi = .none,
    },
    .{
        .cpu_arch = .xtensa,
        .cpu_model = .{ .explicit = &std.Target.xtensa.cpu.esp32s2 },
        .os_tag = .freestanding,
        .abi = .none,
    },
    .{
        .cpu_arch = .xtensa,
        .cpu_model = .{ .explicit = &std.Target.xtensa.cpu.esp32s3 },
        .os_tag = .freestanding,
        .abi = .none,
    },
};

fn isEspXtensa() bool {
    var result = false;
    for (std.Target.Cpu.Arch.xtensa.allCpuModels()) |model| {
        result = std.mem.startsWith(u8, model.name, "esp");
        if (result) break;
    }
    return result;
}
