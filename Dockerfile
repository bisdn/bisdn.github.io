# This Dockerfile can be used to test the website.

# Usage:
# - docker build -t jekyll .
# - docker run --rm -it -v $(pwd):/website -p4000:4000 jekyll
#   Alternatively, when using podman:
#   podman run --rm -it -v $(pwd):/website:O -p4000:4000 jekyll
# - Point browser to http://127.0.0.1:4000/

FROM fedora:36

# Preinstall build requirements for jekyll
RUN dnf install -y ruby-devel redhat-rpm-config g++ zlib-devel

# Install jekyll matching the repo's Gemfile.lock
COPY Gemfile Gemfile.lock /
RUN bundle install

# Serve site on all container interfaces
RUN echo "bundle exec jekyll serve --host 0.0.0.0 --port 4000" >> entrypoint.sh

# Run entrypoint.sh from within the website directory
WORKDIR /website
ENTRYPOINT ["bash", "/entrypoint.sh"]
EXPOSE 4000
