const std = @import("std");

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
                // cannot destroy a null
                self.allocator.destroy(start.?);
                start = next_node;
            }
        }

        pub fn at(self: Self, index: usize) error{OutOfRange}!T {
            const node = try self.nodeAt(index);
            return node.value;
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
    try expect(ll.endNode.?.next == null);

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

test "linkedlist at" {
    var ll = LinkedList(u32).init(testing.allocator);
    defer ll.deinit();

    try ll.append(1);
    try ll.append(2);
    try ll.append(3);

    const node0 = try ll.at(0);
    const node1 = try ll.at(1);
    const node2 = try ll.at(2);

    try expect(node0 == 1);
    try expect(node1 == 2);
    try expect(node2 == 3);
}
