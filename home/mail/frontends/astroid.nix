{ ... }: {
  accounts.email.accounts.personal.astroid = {
    enable = true;
    sendMailCommand = "msmtpq --read-envelope-from --read-recipients";
  };
  programs.astroid = {
    enable = true;
  };
}
