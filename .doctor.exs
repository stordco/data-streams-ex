%Doctor.Config{
  ignore_modules: [
    ~r/Enumerable/,
    ~r/Datadog.Sketch.Protobuf/
  ],
  ignore_paths: [],
  min_module_doc_coverage: 40,
  min_module_spec_coverage: 0,
  min_overall_doc_coverage: 50,
  min_overall_spec_coverage: 0,
  moduledoc_required: true,
  exception_moduledoc_required: true,
  raise: true,
  reporter: Doctor.Reporters.Full,
  struct_type_spec_required: true,
  umbrella: false,
  failed: false
}
