# chat-markdown

The markdown dialect of Gopher Chat, the chat in
[angry-gopher](https://github.com/showell/angry-gopher), rendered to HTML.
It is Zig, on the standard library alone.

The code here was written by AI coding agents (Claude), with human supervision.
Point an agent at this repo to extend it.

**The renderer is the definition of the dialect.** Where it departs from
CommonMark, it does so on purpose. For example, inline markup is per line:
`**`, backticks and `[...]` pair within one line of the source.

## Use

A Zig package: add it to your `build.zig.zon` and import the module
`chat_markdown`, whose root is `src/markdown.zig`.

```
zig build test    # every file's tests
```

## Layout

`src/markdown.zig` is the entry: blocks and the render. Its neighbours in
`src/` each handle one concern (fences, inline markup, links, media, text).

`git log --follow` reaches back into angry-gopher's history, where this code
began. The dialect's benchmark and hostile-input probe live there
(`zig-server/src/markdown_bench.zig`, `markdown_hostile_probe.zig`), since
they read chat transcripts.
