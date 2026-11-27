---
title: "Set up Zig"
description: "Install Zig 0.17 on Linux, macOS or Windows, check it works, and pick an editor."
group: "Welcome"
order: 3
---

# Set up Zig

The course uses **Zig 0.17.0**. Zig changes between versions, so install exactly this one: the code in every
step is tested with it.

## Download

Get the archive for your system from [ziglang.org/download](https://ziglang.org/download/) under **0.17.0**.

### Linux

```sh
tar -xf zig-x86_64-linux-0.17.0.tar.xz
mv zig-x86_64-linux-0.17.0 ~/zig
echo 'export PATH="$HOME/zig:$PATH"' >> ~/.bashrc
```

Open a new terminal. On an ARM machine, take the `aarch64-linux` archive instead.

### macOS

```sh
tar -xf zig-aarch64-macos-0.17.0.tar.xz
mv zig-aarch64-macos-0.17.0 ~/zig
echo 'export PATH="$HOME/zig:$PATH"' >> ~/.zshrc
```

Open a new terminal. On an Intel Mac, take the `x86_64-macos` archive instead.

### Windows

1. Unzip `zig-x86_64-windows-0.17.0.zip` to `C:\zig`.
2. Add `C:\zig` to your `Path`: Start → "Edit the system environment variables" → Environment Variables →
   select `Path` → Edit → New → `C:\zig`.
3. Open a new PowerShell window.

## Check it works

```sh
zig version
```

You should see:

```text
0.17.0
```

::: warning Another version?
If you see a different number, an older Zig is earlier in your `PATH`. Remove it, or put the 0.17.0 folder first.
:::

## An editor

Any text editor works. For hints and errors as you type, use one with the Zig language server, ZLS: for example
Visual Studio Code with the official Zig extension, which can install ZLS for you. Pick the ZLS version that
matches Zig 0.17.

## Next

[Start the course →](/#the-course)
