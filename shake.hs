import           Data.Maybe
import           Data.Monoid
import           Development.Shake
import           Development.Shake.Clean
import           Development.Shake.ClosureCompiler
import           Development.Shake.Command
import           Development.Shake.FilePath
import           Development.Shake.Util
import           System.Directory
import qualified System.IO.Strict                  as Strict

main :: IO ()
main = shakeArgs shakeOptions { shakeFiles = ".shake", shakeLint = Just LintBasic } $ do
    want [ "target/index.html", "README.md" ]

    "deploy" ~> do
        need [ "target/index.html", "target/all.min.js" ]
        cmd ["ion", "-c", "cp target/* ~/programming/rust/nessa-site/static/{{ project }}"]

    "clean" ~> do
        cleanHaskell
        removeFilesAfter "target" ["//*"]
        removeFilesAfter ".shake" ["//*"]

    "README.md" %> \out -> do
        hs <- getDirectoryFiles "" ["src//*.hs"]
        yaml <- getDirectoryFiles "" ["//*.yaml"]
        cabal <- getDirectoryFiles "" ["//*.cabal"]
        mad <- getDirectoryFiles "" ["//*.mad"]
        html <- getDirectoryFiles "" ["web-src//*.html"]
        css <- getDirectoryFiles "" ["web-src//*.css"]
        need $ hs <> yaml <> cabal <> mad <> html <> css
        (Stdout out) <- cmd ["poly", "-c", ".", "-e", "README.md", "-e", "TODO.md", "-e", "target", "-e", "Justfile"]
        file <- liftIO $ Strict.readFile "README.md"
        let header = takeWhile (/= replicate 79 '-') $ lines file
        let new = unlines header ++ out ++ "```\n"
        liftIO $ writeFile "README.md" new

    "dist-newstyle/build/x86_64-linux/ghcjs-0.2.1.9008011/{{ project }}-0.1.0.0/c/{{ project }}/opt/build/{{ project }}/{{ project }}.jsexe/all.js" %> \out -> do
        need . snd =<< getCabalDepsA "{{ project }}.cabal"
        command [RemEnv "GHC_PACKAGE_PATH"] "cabal" ["new-build"]
        -- check the {{ project }}.mad file so we don't push anything wrong
        unit $ cmd ["bash", "-c", "madlang check mad-src/{{ project }}.mad > /dev/null"]
        cmd ["cabal", "new-build"]

    googleClosureCompiler ["dist-newstyle/build/x86_64-linux/ghcjs-0.2.1.9008011/{{ project }}-0.1.0.0/c/{{ project }}/opt/build/{{ project }}/{{ project }}.jsexe/all.js", "dist-newstyle/build/x86_64-linux/ghcjs-0.2.1.9008011/{{ project }}-0.1.0.0/c/{{ project }}/opt/build/{{ project }}/{{ project }}.jsexe/all.js"] "target/all.min.js"

    "target/styles.css" %> \out -> do
        liftIO $ createDirectoryIfMissing True "target"
        need ["web-src/styles.css"]
        cmd ["cp","web-src/styles.css", "target/styles.css"]

    "target/index.html" %> \out -> do
        need ["target/all.min.js", "target/styles.css"]
        cmd ["cp","web-src/index.html", "target/index.html"]
