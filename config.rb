$config = {

  :mongo => {
    :ip => '127.0.0.1',
    :port => 27017,
    :database => 'test'
  },

  :jira => {

    :baseUrl => "https://jira.giffgaff.co.uk/rest/api/2",

    :projects => [
      "Gameplan App",
      "Gameplan Web",
      "Gameplan Money Manager",
      "Gameplan Portfolio",
      "Early Life: Connect",
      "Early Life: Onboard",
      "In Life",
      "Phones",
      "Platform",
      "ReApp",
      "Data"
    ],

    :types => [
      "Story", "Epic", "Spike", "Defect"
    ],

    :fields => [
      "summary",
      "resolutiondate",
      "resolution",
      "created",
      "status",
      "issuetype",
      "customfield_15305", # cycletime
      "customfield_15201",  # lead time
      "project"
    ],

    :headers => [
      "Key",
      "Summary",
      "Created Date",
      "Resolution Date",
      "Status",
      "Type",
      "Lead Time",
      "Cycle Time",
      "Resolution Type",
      "Project"
    ]

  }
}
