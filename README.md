# Documentation on github pages for BISDN Linux and basebox
## Installation

### Local installation

1. Clone the repo to your local machine

2. Change the directory to the cloned repo

```
$ cd ./bisdn.github.io
```

At this point, you can decide to either install the required software on the
host (section "Host installation") or in a container (section "Using
container").

#### Host installation

3. Make sure ruby is installed

```
$ ruby --version
```

4. Package dependencies

4.1 Ensure fedora dependencies are installed

```
$ sudo dnf install ruby-devel redhat-rpm-config gcc++ gcc-c++ zlib zlib-devel
```

5. Install the gem dependencies

```
$ bundle install
```

6. Run the site locally

```
$ bundle exec jekyll serve
```

7. Access your localhost copy

```
$ http://localhost:4000
```

#### Using container

3. Build container image

```
$ docker build -t jekyll .
```

4. Run container

On most platforms, the following command is sufficient to have jekyll serve the
website on the host's http://localhost:4000:

```
$ docker run --rm -it -v $(pwd):/website -p4000:4000 jekyll
```

If you are running on a platform with SELinux enabled, you may get a
"Permission denied" error. There are several solutions for this as
outlined below.

If you are using podman, you can try mounting the bisdn.github.io directory as
an overlay (the container does not need to make any changes to the directory,
let alone permanent ones) using the ':O' suffix.

```
$ podman run --rm -it -v $(pwd):/website:O -p4000:4000 jekyll
```

Alternatively, you can disable SELinux label confinement:

```
$ docker run --rm -it --security-opt label=disable \
  -v $(pwd):/website -p4000:4000 jekyll
```

If you are using docker, there is also the option of having docker relabel the
directory (using the :Z option instead of the :O option mentioned above). Note
that docker will remove any existing label and _not_ remove the label it set
once the container stops running.

## Usage
