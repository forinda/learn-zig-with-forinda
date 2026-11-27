// The course: its 13 parts in order, what each is about, and the "I can ..." competencies it builds (Backward
// Design: competencies first, then the evidence, then the lessons). Every lesson's frontmatter `competency` is
// one of its part's (tests/pages.test.ts). Part titles match src/groups.ts; slugs are the folders under
// src/pages/learn/.

/** `art`: the part's illustration in public/art (the course map shows it), when it has one. */
export type Part = { slug: string; title: string; summary: string; competencies: string[]; art?: string }

export const parts: Part[] = [
  {
    slug: 'start',
    title: 'Start',
    summary: 'Install Zig, write your first program, build, run and test it, and learn to read the compiler.',
    art: '/art/agama-hello.svg',
    competencies: [
      'I can install Zig 0.17 and check its version',
      'I can create, build, run and test a Zig project',
      'I can read a compiler error and fix the code it points to',
    ],
  },
  {
    slug: 'basics',
    title: 'Basics',
    summary: 'Values, types, decisions, loops, functions, arrays, slices and text: a rider moving along a road.',
    competencies: [
      'I can store values in constants and variables of the right type',
      'I can make decisions and repeat work with if, while and for',
      'I can write functions that take and return values',
      'I can work with arrays, slices and text',
    ],
  },
  {
    slug: 'structure',
    title: 'Structure',
    summary: 'Structs, enums, unions, optionals and errors: the rider, the course and the race as types.',
    competencies: [
      'I can model the game with structs, enums and tagged unions',
      'I can handle missing values with optionals and failures with errors',
      'I can write tests for the code I write',
    ],
  },
  {
    slug: 'memory',
    title: 'Memory',
    summary: 'The stack and the heap, allocators, defer and errdefer: a field of riders that grows at runtime.',
    competencies: [
      'I can choose between the stack and an allocator',
      'I can free what I allocate with defer and errdefer',
      'I can find a memory leak with a test',
    ],
  },
  {
    slug: 'data-structures',
    title: 'Data structures',
    summary: 'Lists, maps, ring buffers, queues, sorting, searching and graphs, each where the race needs it.',
    competencies: [
      'I can pick the right data structure for a job and say why',
      'I can sort and search, and measure what they cost',
      'I can find a route through a graph',
    ],
  },
  {
    slug: 'terminal-game',
    title: 'A terminal game',
    summary: 'Read keys, draw frames with escape codes and run a fixed-timestep loop: the race becomes playable.',
    competencies: [
      'I can read keys from the terminal as they are pressed',
      'I can draw a frame of text and redraw it smoothly',
      'I can run a game loop at a fixed timestep',
    ],
  },
  {
    slug: 'simulation',
    title: 'Simulation',
    summary: 'Forces, speed from power, drafting, energy and seeded randomness: riding that feels real.',
    competencies: [
      'I can turn physics into code that steps through time',
      'I can make a simulation give the same result every run',
    ],
  },
  {
    slug: 'ai',
    title: 'AI',
    summary: 'Intents, following wheels, groups and a race director: races that tell a story.',
    competencies: [
      'I can give computer riders goals and let them decide what to do',
      'I can group a field and report what happens in a race',
    ],
  },
  {
    slug: 'file-io',
    title: 'File I/O',
    summary: 'Files, readers and writers, JSON, versions and migrations, safe writes: a career that persists.',
    competencies: [
      'I can read and write files safely',
      'I can save data as JSON and load older versions of it',
    ],
  },
  {
    slug: 'build-system',
    title: 'The build system',
    summary: 'build.zig, options, several programs, modules, generated files, dependencies and cross-compiling.',
    competencies: [
      'I can describe a project in build.zig with several programs and modules',
      'I can add a dependency and build for another operating system',
    ],
  },
  {
    slug: 'c-libraries',
    title: 'C libraries',
    summary: 'Call C from Zig, link and compile C code, and wrap a C API: results and records in SQLite.',
    competencies: [
      'I can call a C library from Zig',
      'I can compile C code with build.zig and wrap its API safely',
    ],
  },
  {
    slug: 'networking',
    title: 'Networking',
    summary: 'Sockets, a server and clients, a message protocol and lockstep: race your friends.',
    competencies: [
      'I can send and receive messages over TCP',
      'I can keep a game in step across machines',
    ],
  },
  {
    slug: 'hero',
    title: 'Hero',
    summary: 'comptime and generics, profiling, data-oriented design and shipping a release.',
    competencies: [
      'I can write generic code with comptime',
      'I can measure and speed up a program, and ship it',
    ],
  },
]
