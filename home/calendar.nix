{ pkgs, ... }: {
  accounts.calendar = {
    basePath = "~/sync/calendar";
    accounts.personal = {
      remote.passwordCommand = [ "pass" "show" "google/caldav_client_secret" ];
      remote.url = "";
      remote.userName = "26134452286-cbc87mv6qou3nlhgtp6fhhuhl8t8bhi3.apps.googleusercontent.com";
      remote.type = "google_calendar";
      vdirsyncer = {
        enable = true;
        timeRange = {
          end = "datetime.now() + timedelta(days=365)";
          start = "datetime.now() - timedelta(days=365)";
        };
      };
      khal = {
        enable = true;
        readOnly = true;
      };
    };
  };
}
