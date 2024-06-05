const String fetchPatientsQuery = """
query FetchPatients {
  hms_patient {
    id
    name
    email
    mobile
  }
}
""";
