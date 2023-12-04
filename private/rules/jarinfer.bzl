load("//:specs.bzl", "parse")
load(":jvm_import.bzl", "jvm_import")

MAX_HEAP_SIZE = "1g"
JARINFER_MNEMONIC = "Jarinfer"
DEFAULT_ATTRS = {
    "_jarinfer_rule": attr.label(
        default = Label("@rules_jvm_external//third_party/jarinfer"),
        executable = True,
        cfg = "host",
    ),
    "srcs": attr.label_list(allow_files = [".jar", ".aar"]),
}

def _impl(ctx, classes_jar, classpath_list, outfile_name):
    args = ctx.actions.args()
    args.add("-b")
    args.add("--strip-jar-signatures")
    args.add("--input-file", classes_jar)
    args.add("--output-file", outfile_name)

    classpath = ":".join([input.path for input in classpath_list])
    ctx.actions.run(
        inputs = [classes_jar],
        outputs = [outfile_name],
        executable = ctx.executable._jarinfer_rule,
        mnemonic = JARINFER_MNEMONIC,
        progress_message = "Running Jarinfer for %{label}",
        arguments = [args],
        env = {"JAVA_OPTS": "-Xmx{}".format(MAX_HEAP_SIZE), "CLASSPATH": "{}".format(classpath)},
    )

def _jarinfer_impl(ctx):
    srcs = ctx.attr.srcs
    outfiles = []
    for src in srcs:
        for artifact in src.files.to_list():
            if artifact.extension != "aar" and artifact.extension != "jar":
                continue
            jarinfer_artifact_name = "jarinfer_" + artifact.owner.name + "_" + artifact.basename
            outfile = ctx.actions.declare_file(jarinfer_artifact_name)
            _impl(ctx, artifact, [artifact], outfile)
            outfiles.append(outfile)

    return [DefaultInfo(files = depset(outfiles))]

jarinfer = rule(
    implementation = _jarinfer_impl,
    doc = """JarInfer Bazel rule""",
    attrs = DEFAULT_ATTRS,
)


def jarinfer_aar_import(name, aar, _aar_import = None, visibility = None, **kwargs):
    jarinfer(
        name = "jarinfer" + name,
        srcs = [aar],
        visibility = visibility,
    )

    if not _aar_import:
        _aar_import = native.aar_import

    _aar_import(
        name = name,
        aar = ":jarinfer" + name,
        visibility = visibility,
        **kwargs
    )

def jarinfer_jvm_import(name, jars, visibility = None, **kwargs):
    jarinfer(
        name = "jarinfer" + name,
        srcs = jars,
        visibility = visibility,
    )

    jvm_import(
        name = name,
        jars = [":jarinfer" + name],
        visibility = visibility,
        **kwargs
    )
