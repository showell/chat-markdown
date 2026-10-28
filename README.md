# chat-markdown

The markdown dialect of Gopher Chat (lynrummy.com/chat), rendered to HTML, in
Zig with no dependencies beyond the standard library.

**The renderer is the definition of the dialect.** There is no outside
oracle. Where it departs from CommonMark, it does so on purpose. For example,
inline markup is per line: `**`, backticks and `[...]` never pair across a
hard wrap.

## Use

A Zig package: add it to your `build.zig.zon` and import the module
`chat_markdown`, whose root is `src/markdown.zig`.

```
zig build test    # every file's tests
```

## Layout

- `src/markdown.zig` is the entry: blocks and the render.
- Its neighbours, each imported from it, handle one concern apiece:
  - `markdown_fence.zig`: code fences;
  - `markdown_inline.zig`: inline markup;
  - `markdown_links.zig`: links;
  - `markdown_media.zig`: images and media;
  - `markdown_text.zig`: text and escaping.

The history before this repository is angry-gopher's; it was split out with
`git filter-branch`, so `git log --follow` reaches back through it.

## Not here yet

The regression harness, which renders frozen corpora and compares them with
the gold, still lives in angry-gopher (`zig-server/src/markdown_regression_test.zig`,
`ops/check_markdown`), with the benchmark and the hostile-input probe. All three
read chat transcripts to gather messages.
