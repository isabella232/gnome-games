# Compilation and Installation Procedure
You can install this project either manually (by command line) or with [Builder](https://wiki.gnome.org/Apps/Builder "GNOME Builder Wiki").

## Manual installation
### Get the official git repository
```shell
git clone https://gitlab.gnome.org/GNOME/gnome-games.git
```

### Get dependencies
Games always requires the matching version of [RetroGTK](https://gitlab.gnome.org/GNOME/retro-gtk "RetroGTK GitLab"), [libmanette](https://gitlab.gnome.org/GNOME/libmanette "libmanette GitLab") and [libhandy](https://gitlab.gnome.org/GNOME/libhandy "libhandy"), so if you use the master version of Games, you need to use the master version of RetroGTK, libmanette and libhandy.

### Prepare compilation
```shell
meson _build
```

### Compilation
``` shell
ninja -C _build
```

### Install the application
```shell
sudo ninja -C _build install
```

# Coding Style Guidelines

## Vala code
The coding style to respect in this project is very similar to most Vala projects.

* Use 4-spaces wide tabs (and not spaces) for indentation.

* Use spaces for alignment.

* _Prefer_ lines of less than <= 80 columns.

* 1-space between function name and braces (both calls and signature declarations).

* If a function signature/call fits in a single line, do not break it into multiple lines.

* for methods/functions that take variable argument tuples, all the first elements of tuples are indented normally with subsequent elements of each tuple indented 4-spaces more. Like this:
```
action.get ("ObjectID",
			 	 typeof (string),
				 out this.object.id,
			"Filter",
				 typeof (string),
				 out this.filter,
			"StartingIndex",
				 typeof (uint),
				 out this.index,
			"RequestedCount",
				 typeof (uint),
				 out this.requested_count,
			"Sortcriteria",
				 typeof (uint),
				 out this.sort_criteria);
```

* Single statements inside `if`/`else` must not be enclosed by `{}`.

* Provide docs in comments, but avoid over-documenting while doing so. An example of a useless comment would be:
```
//fetch the document
fetch_the_document ();
```

* Add a newline to break the code into logical pieces.

* Add a newline before each return, throw, break, continue etc. if it is not the only statement in that block.
```
   if (condition_applies ()) {
       do_something ();

       return false;
   }

   if (other_condition_applies ())
       return true;
```

   Except for the break in a switch:
```
   switch (val) {
   case 1:
       debug ("case 1");
       do_one ();
       break;

   default:
       ...
   }
```

* Give the `case` statements the same indentation level as their `switch` statement.

* Add a newline at the end of each file.

* _Prefer_ descriptive names over abbreviations (unless well-known) & shortening of names. E.g. `discoverer` over `disco`.

* Use `var` in variable declarations wherever possible.

* Don't use `var` when declaring a number from a literal.

* Use `as` to cast wherever possible.

* Avoid the use of the `this` keyword when possible.

* Don't use any `using` statements.

* Prefer `foreach` over `for`.

* Each class should go in a separate .vala file which should be named according to the class in it, but in kebab-case. E.g. the Games.GameSource class should go under game-source.vala.

* Declare the namespace(s) of the class/errordomain with the class/errordomain itself. Like this:
```
private class Games.Hello {
	...
};
```

* Use GObject-style construction whenever possible.

* Prefer properties over methods whenever possible.

* Declare properties getters before the setters.

* If a function returns several equally important values, they should all be given out as arguments. In other words, prefer this: 
```
void get_a_and_b (out string a, out string b)
```

over this:
```
string get_a_and_b (out string b)
```

* Use method as callbacks to signals.

* _Prefer_ operators over methods when possible. E.g. prefer `collection[key]` over `collection.get(key)`.

* If a function or a method can be used as a callback, don't enclose it in a lambda. E.g. do `do (callback)` rather than `do (() => callback ()) `.

* Limit the try blocks to the code throwing the error.

* Anything that can be `private` must be `private`.

* Avoid usage of the `protected` visiblity

* Use the `internal` visibility carefully.

* Always add a comma after the enumerated value of an enum type.

* Always add a comma after the final error code of an errordomain type.

* Any `else`, `else if`, `catch` or any other special block
   following another one should start in its own line and not on the
   same as the previous closing brace.

 * Internationalize error messages, which implies using printf style
   string construction rather than string templates.

 * Append the original error message to the one you are building when refining an error.

## C code

For C code, the following rules apply, inspired by several other GObject projects.

* Use 2 spaces for indentation.

* _Prefer_ lines of less than <= 80 columns

* Leave a 1-space between function name and braces (both calls and signature)

* Add a newline to break the code in logical pieces.

* Add a newline before each `return`, `break`, `continue` etc. if it is not the only statement in that block.
```
if (condition_applies (self)) {
       do_something (self);

       return FALSE;
   }

   if (other_condition_applies ())
       return TRUE;
```

* Give the `case` statements the same indentation level as their
   `switch` statement.

* Add a newline at the end of each file.

* In C files, function definitions are split into lines in the following way:
	+ modifiers and the returned type at the beginning of the line;
	+ the function name and the first parameter (if any) at the beginning of the line;
	+ each extra parameter has its own line, aligned with the first
parameter;
	+ the opening curly brace at the beginning of the line.

* In header files, function definitions are split into lines in the following way:
	+ modifiers, the returned type, the function name and the first parameter (if any) at the beginning of the line;
    + each extra parameter has its own line, aligned with the first parameter;
    + the opening curly brace at the beginning of the line.

* Provide docs in comments, but avoid over-documenting while doing so. An example of a useless comment would be:
```
//fetch the document
fetch_the_document ();
```

* Any `else` , `else if` block or any other special block following another one should start in its own line and not on the same as the previous closing brace.

* _Prefer_ descriptive names over abbreviations (unless well-known) & shortening of names. E.g. `discoverer` over `disco`.

* Functions with no parameters should state it with the `void` keyword.

* Use static functions instead of nested ones.

* Don't use single statement blocks.

* Each class should go in a separate .c and .h file which should be named according to the class in it, but in kebab-case. E.g. the Games.GameSource class should go under game-source.h and game-source.c.

* If a function returns several equally important values, they should all be given as out arguments. In other words, prefer this:
```
void get_a_and_b (gchar **a, gchar **b)
```

over this:
```
gchar *get_a_and_b (gchar **b)
```

* Anything that can be `private` (`static` to the C file) must be
   `private`.

* Always add a comma after the enumerated value of an enum type broken into multiple lines.

* Always add a comma after values of an array literal broken into
   multiple lines.

* Append the original error message to the one you are building when refining an error.

# Commit Message Guidelines

Follow GNOME's commit message guidelines: <https://wiki.gnome.org/Git/CommitMessages>
To these rules we add some others.

General rules:
* In the description, try to fill your lines as much as possible (don't go to the next line when the word you want to write still fits onto the current line).
* Don't go to the next line after finishing a sentence if you still have enough space for more words.
* Split the paragraphs with two newlines (one empty line).
* If the context isn't sufficient, be explicit with the types and namespaces of the codepoints you cite.
* Suffix methods and functions with parentheses (without the space) so other people know the name refers to an operation when they read your commit.
* Write property names between single quotes and in kebab-case.

The tag can be:
* The name of the sub-directory of data, plugins or src in which the change was made
* `build` if it affects the build system
* anything else that seems more appropriate for the change
* nothing if multiple parts were affected

The actual changes:
* The first paragraph explains what the commit does from an objective point of view: the code change.
* If the shortlog is explicit enough, this first paragraph can be omitted.
* Try to start sentences by the action performed and try using the infinitive.
