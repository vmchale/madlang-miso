size:
    @sn d target/all.min.js

script:
    @mkdir -p .shake
    @cp shake.hs .shake
    cd .shake && ghc-8.2.2 -O2 shake.hs -o build
    @mv .shake/build .

view:
    firefox target/index.html
