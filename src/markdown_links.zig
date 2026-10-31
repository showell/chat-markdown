//! markdown_links: the MSG_-reference + external-link rules, applied INLINE by
//! the inline pass at emit time (it used to be a post-pass that re-tokenized the
//! finished HTML to re-discover code/link interiors — structure the inline pass
//! already knows, so it now decides where the structure is still in hand). Two
//! pure helpers over markdown_text:
//!   linkifyAndEscape — emit a plain-text run, MSG_<topic>_<n> and
//!                      MSG_<channel>.<topic>_<n> → reference link,
//!                      everything else HTML-escaped.
//!   external_attrs   — the new-tab attributes for an external (scheme://) href.

const std = @import("std");
const mtext = @import("markdown_text.zig");

// Leaf text helpers (see markdown_text); aliased so the bodies read unqualified.
const isWordChar = mtext.isWordChar;
const isSlugChar = mtext.isSlugChar;
const isDigit = mtext.isDigit;
const isAsciiAlpha = mtext.isAsciiAlpha;
const isAsciiAlnum = mtext.isAsciiAlnum;

/// external_attrs opens a link in a new tab without leaking the opener. Appended
/// to an <a> whose href isExternalHref. One source of truth for both the
/// markdown-link and autolink emit sites.
pub const external_attrs = " target=\"_blank\" rel=\"noopener\"";

/// appendMsgRef writes a `MSG_<slug>` reference link for `slug` (the group
/// msgRefEnd captures: `<topic>_<n>`, or `<channel>.<topic>_<n>`). Both grammars
/// hold no HTML-special bytes, so the slug is emitted verbatim into both the
/// href and the visible text. The href names no URL: where the reference goes is
/// the host's to decide (the client reads `#msg-<slug>`).
pub fn appendMsgRef(out: *std.ArrayList(u8), a: std.mem.Allocator, slug: []const u8) !void {
    try out.appendSlice(a, "<a href=\"#msg-");
    try out.appendSlice(a, slug);
    try out.appendSlice(a, "\" class=\"msg-ref\">MSG_");
    try out.appendSlice(a, slug);
    try out.appendSlice(a, "</a>");
}

/// The longest channel name, in bytes (a channel is a letter, then letters,
/// digits and hyphens).
const channel_name_max = 40;

/// msgRefEnd matches a reference at text[i], returning the index just past it,
/// or null. Two forms, each between word boundaries:
///   \bMSG_([A-Za-z0-9-]+_[0-9]+)\b                         a topic's message,
///                                                          on this page only
///   \bMSG_([A-Za-z][A-Za-z0-9-]{0,39}\.[A-Za-z0-9-]+_[0-9]+)\b  a channel's
///                                                          topic's message
/// Neither name can hold `.` or `_`, so a reference reads one way only. The
/// inline pass calls this DURING the scan (not after) so a MSG_ ref becomes one
/// atomic token before its `_` characters could be mistaken for emphasis
/// delimiters.
pub fn msgRefEnd(text: []const u8, i: usize) ?usize {
    if (i + 4 > text.len or !std.mem.eql(u8, text[i .. i + 4], "MSG_")) return null;
    if (i > 0 and isWordChar(text[i - 1])) return null; // \b before
    var j = slugEnd(text, i + 4) orelse return null;
    if (j < text.len and text[j] == '.') {
        // The long form: what came first is a channel's name.
        const channel = text[i + 4 .. j];
        if (channel.len > channel_name_max or !isAsciiAlpha(channel[0])) return null;
        j = slugEnd(text, j + 1) orelse return null;
    }
    if (j >= text.len or text[j] != '_') return null;
    j += 1;
    const dig_start = j;
    while (j < text.len and isDigit(text[j])) : (j += 1) {}
    if (j == dig_start) return null;
    if (j < text.len and isWordChar(text[j])) return null; // \b after
    return j;
}

/// The end of a run of slug characters (letters, digits, hyphens) starting at
/// text[start], or null for none.
fn slugEnd(text: []const u8, start: usize) ?usize {
    var j = start;
    while (j < text.len and isSlugChar(text[j])) : (j += 1) {}
    return if (j == start) null else j;
}

/// isExternalHref is true for a fully-qualified `scheme://…` href (the ones we
/// open in a new tab). Internal links (`#msg-…`, `/chat/…`) and `mailto:` are not.
pub fn isExternalHref(href: []const u8) bool {
    const p = std.mem.indexOf(u8, href, "://") orelse return false;
    if (p == 0 or !isAsciiAlpha(href[0])) return false;
    for (href[1..p]) |c| {
        if (!isAsciiAlnum(c) and c != '+' and c != '.' and c != '-') return false;
    }
    return true;
}

test "msgRefEnd: a topic's reference and a channel's, each read whole; anything else is no reference" {
    const cases = [_]struct { text: []const u8, end: ?usize }{
        // The short form, as before.
        .{ .text = "MSG_plans_3", .end = 11 },
        .{ .text = "MSG_plans_3.", .end = 11 },
        .{ .text = "MSG_road-trip-2_12 then", .end = 18 },
        // The long form: a channel's name, a `.`, then the short form.
        .{ .text = "MSG_Cobblestone.ChitChat_5", .end = 26 },
        .{ .text = "MSG_Cobblestone.ChitChat_5.", .end = 26 },
        .{ .text = "MSG_a-1-.road-trip_9 x", .end = 20 },
        .{ .text = "MSG_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.t_1", .end = 4 + 40 + 4 },
        // Not one: no number, a name too long, a channel not led by a letter,
        // an empty name, two dots, a word character after.
        .{ .text = "MSG_x.y", .end = null },
        .{ .text = "MSG_x.y_", .end = null },
        .{ .text = "MSG_Cobblestone.ChitChat", .end = null },
        .{ .text = "MSG_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.t_1", .end = null },
        .{ .text = "MSG_1st.ChitChat_5", .end = null },
        .{ .text = "MSG_-a.ChitChat_5", .end = null },
        .{ .text = "MSG_.ChitChat_5", .end = null },
        .{ .text = "MSG_a._5", .end = null },
        .{ .text = "MSG_a.b.c_5", .end = null },
        .{ .text = "MSG_a.b_5x", .end = null },
        .{ .text = "MSG_a.b_5_6", .end = null },
    };
    for (cases) |c| try std.testing.expectEqual(c.end, msgRefEnd(c.text, 0));
    // A word character before is no boundary.
    try std.testing.expectEqual(@as(?usize, null), msgRefEnd("xMSG_a.b_5", 1));
}
