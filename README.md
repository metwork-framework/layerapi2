#  layerapi2

[//]: # (automatically generated from https://github.com/metwork-framework/resources/blob/master/cookiecutter/_%7B%7Bcookiecutter.repo%7D%7D/README.md)

**Status (master branch)**



[![Drone CI](http://metwork-framework.org:8000/api/badges/metwork-framework/layerapi2/status.svg)](http://metwork-framework.org:8000/metwork-framework/layerapi2)
[![Maintenance](https://github.com/metwork-framework/resources/blob/master/badges/maintained.svg)]()


**Table of contents**

* [1\. What is it ?](#1-what-is-it-)
* [2\. Concepts](#2-concepts)
* [3\. Tools](#3-tools)
* [4\. Contributing guide](#4-contributing-guide)
* [5\. Code of Conduct](#5-code-of-conduct)
* [6\. Sponsors](#6-sponsors)



## 1. What is it ?

`layerapi2` module is a library and a set of cli tools to manage a layered environment
system.

A similar system is [environment modules](http://modules.sourceforge.net/). `layerapi2` module
is more simple, probably more opinionated and reliable but less HPC oriented and deals with only one
compiler.

Initially designed for use in [MetWork Framework](http://www.metwork-framework.org), it's now
a completly independant repository.

## 2. Concepts

### 2.1 Layers

A layer is defined by:

- a layer label (a string, not necessarily unique)
- a layer home (a full path to a directory)

Optionally, a layer definition can include:

- some dependencies (just a list of other layer labels)
- some conflicts (just a list of other layer labels)
- some environment variables to set/unset during layer load/unload
- some extra interactive profile to load/unload during layer load/unload

So concretely, a layer is a directory with the following structure:

```
    /path/to/my/layer/
                     /.layerapi2_label
                     /.layerapi2_dependencies
                     /.layerapi2_conflicts
                     /.layerapi2_extra_env
                     /.layerapi2_interactive_profile
                     /.layerapi2_interactive_unprofile
```

The only mandatory file is `.layerapi2_label`. It contains the layer label on its first and
only line.

### 2.2 Layers path

The environment variable `LAYERAPI2_LAYERS_PATH` contains a ":" separated list
of directories full paths.

When we search a given layer, we iterate the list from the beginning and for each
directory full path, we test:

- if the selected directory is a layer by itself (ie. it contains a `.layerapi2_label` file)
- if immediate subdirectories are layers

Consider the following example:

```
    /path1/layer1/
    /path1/layer1/.layerapi2_label (containing "layer1label")
    /path2/layers/
    /path2/layers/layer2/
    /path2/layers/layer2/.layerapi2_label (containing "layer2label")
    /path3/layers/layer3/
    /path3/layers/layer3/.layerapi2_label (containing "layer3label")
```

If the value of `LAYERAPI2_LAYERS_PATH` is `/path1/layer1:/path2/layers:/path3`:

- we will find (by its label) the layer "layer1label" because it's directly pointed
by the `/path1/layer1` value
- we will find (by its label) the layer "layer2label" because `/path2/layers/layer2` (its home)
is an immediate subdirectory of the `/path2/layers` value
- we won't find (by its label) the layer "layer3label" because `/path3/layers/layer3` (is home) is not an immediate subdirectory of the `/path3` value

Notes:

- relative paths in `LAYERAPI2_LAYERS_PATH` are ignored
- if there are several layer homes for a given label (ie. multiple directories with the same value for `.layerapi2_label` file),
the first occurrence is returned when searching by label
(so the order of entries in LAYERAPI2_LAYERS_PATH can be important).

### 2.3 Installation / Loading / Unloading

We consider that a layer is *installed* if we can found it by its label through the layers path.

When a layer is *installed*, nothing is done automatically. It's just available for loading.

Then a layer can be loaded. When the layer is loaded, the environment is modified. We will see
that in more detail a little further.

When a layer is loaded, it can be unloaded. Then, the corresponding environment modification is reversed.

## 3. Tools

### 3.1 `layers`

The `layers` utility list installed layers. You can also filter the output to get:

- only loaded layers
- only not loaded (but installed) layers

If you don't see your layer in `layers` output, check your `LAYERAPI2_LAYERS_PATH` environment
variable and if there is a `.layerapi_label` in your layer home.

Full documentation:

```console
Usage:
  layers [OPTION...] - list installed layers

Help Options:
  -h, --help              Show help options

Application Options:
  -r, --raw               raw output
  -m, --loaded-filter     Loaded layer filter (default: no filter, possible values: yes, no)

```

In the default output:

- you have the layer label, then the layer home
- you have `(*)` before the layer label if the corresponding layer is already loaded

You can also filter only "not loaded" (but installed) layers with the following call:

```console
layers --loaded-filter=no
```

### 3.2 `is_layer_installed`, `is_layer_loaded`

These two little utilities output `1` is the layer given as argument is installed/loaded.

```console
Usage:
  is_layer_installed [OPTION...] LAYER LABEL - output 1 is the given layer is installed

Help Options:
  -h, --help       Show help options

```

```console
Usage:
  is_layer_loaded [OPTION...] LAYER LABEL OR LAYER HOME - output 1 is the given layer is already loaded

Help Options:
  -h, --help       Show help options

```

### 3.3 `layer_wrapper`

This is probably the most interesting and the most useful utility.

First, let's have a look at full options:

```console
Usage:
  layer_wrapper [OPTION...] -- COMMAND [COMMAND_ARG1] [COMMAND_ARG2] [...] - wrapper to execute the given command in a process with some specific layers loaded

Help Options:
  -h, --help                 Show help options

Application Options:
  -d, --debug                debug mode
  -e, --empty                unload all layers before
  -c, --cwd                  change working directory to the last layer home
  -x, --extra-env-prefix     if set, add three environnement variables {PREFIX}_NAME, {PREFIX}_LABEL and {PREFIX}_DIR containing the last layer name, label and the last layer home 
  -E, --empty-env            empty environnement (imply --empty)
  -k, --empty-env-keeps      coma separated list of env var to keep with --empty-env
  -l, --layers               coma separated list of layers labels/homes ('-' before the name of the layer means 'optional dependency')
  -p, --prepend-env          ENV_VAR,VALUE string to prepend VALUE in : separated ENV_VAR (like PATH) (can be used multiple times)
  -f, --force-prepend        do not check existing paths in prepend
  --dont-load-optional       don't load optional layers

```

This command can be used to launch another command in a new process but within a context
where some additional layers are loaded. The original context won't be modified.

For example:

```console
$ is_layer_loaded foo
0
    => The layer "foo" is not loaded

$ layer_wrapper --layers=foo -- is_layer_loaded foo
1
    => We launched "is_layer_loaded foo" in a new process/context
       within the layer "foo" is loaded

$ is_layer_loaded foo
0
    => The original context is not modified
```

Another more complex example:

```console
$ layers
- (*) layer1 [/tests/layer1]
- layer2 [/tests/layer2]
- layer3 [/tests/layer3]
    => We have 3 layers installed, only the first one is loaded

$ layer_wrapper --debug --empty --layers=layer2,layer3 -- layers
[DEBUG]: unloading layer1[/tests/layer1]
[DEBUG]: loading layer2[/tests/layer2]
[DEBUG]: loading layer3[/tests/layer3]
- layer1 [/tests/layer1]
- (*) layer2 [/tests/layer2]
- (*) layer3 [/tests/layer3]
    => We launched the "layers" command in a new context with first all layers
       unloaded then layer2 and layer3 loaded

$ layers
- (*) layer1 [/tests/layer1]
- layer2 [/tests/layer2]
- layer3 [/tests/layer3]
    => the original context is not modified
```

### 3.4 `layer_load_bash_cmds`, `layer_unload_bash_cmds`

Two very important utilities are `layer_load_bash_cmds` and `layer_unload_bash_cmds`.

They output bash commands to source/eval in order to change the current context with the given
layer loaded/unloaded (included all dependencies management).

```console
Usage:
  layer_load_bash_cmds [OPTION...] LAYER_LABEL OR LAYER_HOME - output bash commands to eval to load the given layer

Help Options:
  -h, --help               Show help options

Application Options:
  -d, --debug              debug mode
  --dont-load-optional     don't load optional layers
  -f, --force-prepend      do not check existing paths in prepend

```

```console
Usage:
  layer_unload_bash_cmds [OPTION...] LAYER_LABEL OR LAYER_HOME - output bash commands to eval to unload the given layer

Help Options:
  -h, --help       Show help options

Application Options:
  -d, --debug      debug mode

```

We recommend to define in your bash environment two bash functions like this:

```bash
    function layer_load() {
        eval "$(layer_load_bash_cmds --debug "$1")"
    }

    function layer_unload() {
        eval "$(layer_unload_bash_cmds --debug "$1")"
    }

    # Note: you can of course remove the "--debug" string if you don't want it
```

And use these two bash functions instead of `layer_load_bash_cmds`, `layer_unload_bash_cmds`
binaries directly. 

FIXME: full tutorial




## 4. Contributing guide

See [CONTRIBUTING.md](CONTRIBUTING.md) file.



## 5. Code of Conduct

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) file.



## 6. Sponsors

*(If you are officially paid to work on MetWork Framework, please contact us to add your company logo here!)*

[![logo](https://raw.githubusercontent.com/metwork-framework/resources/master/sponsors/meteofrance-small.jpeg)](http://www.meteofrance.com)
