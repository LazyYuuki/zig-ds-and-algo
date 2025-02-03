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

// - LinkedList
// - Stacks
// - Queues
pub fn Node(comptime T: type) type {
    return struct {
        prev: ?*Node(T),
        next: ?*Node(T),
        value: T,
    };
}

pub fn LinkedList(comptime T: type) type {
    return struct {
        const Self = @This();

        length: usize,
        startNode: ?*Node(T),
        endNode: ?*Node(T),
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .length = 0,
                .startNode = null,
                .endNode = null,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            var start = self.startNode;
            while (start != null) {
                const next_node: ?*Node(T) = start.?.next;
                self.allocator.destroy(start.?);
                start = next_node;
            }
        }

        pub fn nodeAt(self: Self, index: usize) error{OutOfRange}!*Node(T) {
            if (index >= self.length) {
                return error.OutOfRange;
            }

            var i: usize = 0;
            var res = self.startNode;
            while (i <= index) : (i += 1) {
                if (i == index) return res.?;
                res = res.?.next;
            }
            unreachable;
        }

        pub fn append(self: *Self, value: T) error{OutOfMemory}!void {
            const new_node = try self.allocator.create(Node(T));

            if (self.length == 0) {
                new_node.* = .{
                    .prev = null,
                    .next = null,
                    .value = value,
                };

                self.startNode = new_node;
                self.endNode = new_node;
                self.length += 1;
                return;
            }

            new_node.* = .{
                .prev = self.endNode,
                .next = null,
                .value = value,
            };

            self.endNode.?.next = new_node;
            self.endNode = new_node;
            self.length += 1;
        }
    };
}

const testing = std.testing;
const expect = testing.expect;

test "linkedlist init" {
    var ll = LinkedList(u32).init(testing.allocator);
    defer ll.deinit();

    try expect(ll.length == 0);
    try expect(ll.startNode == null);
    try expect(ll.endNode == null);
}

test "linkedlist append" {
    var ll = LinkedList(u32).init(testing.allocator);
    defer ll.deinit();

    try ll.append(1);

    try expect(ll.startNode == ll.endNode);
    try expect(ll.startNode.?.value == 1);
    try expect(ll.startNode.?.prev == null);
    try expect(ll.startNode.?.next == null);
    try expect(ll.length == 1);

    try ll.append(2);

    try expect(ll.startNode.?.value == 1);
    try expect(ll.startNode.?.prev == null);
    try expect(ll.startNode.?.next == ll.endNode);

    try expect(ll.endNode.?.value == 2);
    try expect(ll.endNode.?.prev == ll.startNode);
    try expect(ll.endNode.?.next == null);

    try ll.append(3);

    try expect(ll.startNode.?.value == 1);
    try expect(ll.startNode.?.prev == null);

    try expect(ll.endNode.?.value == 3);
    // try expect(ll.endNode.?.next == null);

    try expect(ll.length == 3);
}

test "linkedlist nodeAt" {
    var ll = LinkedList(u32).init(testing.allocator);
    defer ll.deinit();

    try ll.append(1);
    try ll.append(2);
    try ll.append(3);

    const node0 = try ll.nodeAt(0);
    const node1 = try ll.nodeAt(1);
    const node2 = try ll.nodeAt(2);

    try expect(node0.value == 1);
    try expect(node1.value == 2);
    try expect(node2.value == 3);

    try expect(node0.prev == null);
    try expect(node0.next == node1);
    try expect(node1.next == node2);
    try expect(node2.next == null);
}

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
