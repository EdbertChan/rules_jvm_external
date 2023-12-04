java_import (
    name = "jarinfer_jars",
    jars = glob(["jarinfer-standalone/lib/*.jar"]),
)

java_binary(
    name = "jarinfer",
    main_class = "com.uber.nullaway.jarinfer.JarInfer",
    visibility = ["//visibility:public"],
    runtime_deps = [
        ":jarinfer_jars"
    ],
)
