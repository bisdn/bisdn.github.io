# Documentation on github pages for BISDN Linux and basebox
## Installation

### Local installation

1. Clone the repo to your local machine

2. Change the directory to the cloned repo

```
$ cd ./bisdn.github.io
```

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

## Usage
