const std = @import("std");

// - Array
pub fn ArrayList(comptime T: type) type {
    return struct {
        const Self = @This();

        items: []T,
        capacity: usize,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .items = &[_]T{},
                .capacity = 0,
                .allocator = allocator,
            };
        }

        pub fn initWithCapacity(allocator: std.mem.Allocator, capacity: usize) std.mem.Allocator.Error!Self {
            var self = Self.init(allocator);
            const memory = try self.allocator.alloc(T, capacity);
            self.items.ptr = memory.ptr;
            self.items.len = 0;
            self.capacity = memory.len;
            return self;
        }

        pub fn append(self: *Self, item: T) std.mem.Allocator.Error!void {
            if (self.items.len + 1 > self.capacity) {
                try self.resize(self.capacity * 2);
            }

            self.items.ptr[self.items.len] = item;
            self.items.len += 1;
        }

        pub fn resize(self: *Self, size: usize) std.mem.Allocator.Error!void {
            const new_arr = try self.allocator.alloc(T, size);
            const length = self.items.len;
            self.allocator.free(self.items.ptr[0..self.capacity]);
            self.items.ptr = new_arr.ptr;
            self.items.len = length;
            self.capacity = size;
        }

        pub fn deinit(self: Self) void {
            self.allocator.free(self.items.ptr[0..self.capacity]);
        }
    };
}

const testing = std.testing;
const expect = testing.expect;

test "array init" {
    const arr = ArrayList(u32).init(std.testing.allocator);

    try expect(@TypeOf(arr) == ArrayList(u32));
    try expect(@TypeOf(arr.items) == []u32);
    try expect(arr.items.len == 0);
    try expect(arr.capacity == 0);
    try expect(@TypeOf(arr.allocator) == std.mem.Allocator);
}

test "array init with capacity" {
    const arr = try ArrayList(u32).initWithCapacity(std.testing.allocator, 5);
    defer arr.deinit();

    try expect(@TypeOf(arr) == ArrayList(u32));
    try expect(@TypeOf(arr.items) == []u32);
    try expect(arr.items.len == 0);
    try expect(arr.capacity == 5);
    try expect(@TypeOf(arr.allocator) == std.mem.Allocator);
}

test "array resize" {
    var arr = try ArrayList(u32).initWithCapacity(std.testing.allocator, 5);
    defer arr.deinit();

    try arr.resize(10);
    try expect(arr.items.len == 0);
    try expect(arr.capacity == 10);
}

test "array append" {
    var arr = try ArrayList(u32).initWithCapacity(std.testing.allocator, 2);
    defer arr.deinit();

    try arr.append(2);
    try expect(arr.items[0] == 2);

    try arr.append(4);
    try expect(arr.items[1] == 4);

    try expect(arr.capacity == 2);
    try expect(arr.items.len == 2);

    // resize here
    try arr.append(8);
    try expect(arr.items[2] == 8);

    try expect(arr.capacity == 4);
    try expect(arr.items.len == 3);
}

test "array deninit" {
    const arr = ArrayList(u32).init(std.testing.allocator);
    arr.deinit();
}
