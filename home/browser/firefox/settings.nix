{
  # FASTFOX
  "nglayout.initialpaint.delay" = 0;
  "nglayout.initialpaint.delay_in_oopif" = 0;
  "content.notify.interval" = 100000;
  "browser.startup.preXulSkeletonUI" = false;
  "layout.css.grid-template-masonry-value.enabled" = true;
  "layout.css.has-selector.enabled" = true;
  ## GFX
  "gfx.webrender.precache-shaders" = true;
  "gfx.canvas.accelerated.cache-items" = 4096;
  "gfx.canvas.accelerated.cache-size" = 512;
  "gfx.content.skia-font-cache-size" = 20;
  ## BROWSER CACHE
  "browser.cache.memory.capacity" = 1048576;
  "browser.cache.memory.max_entry_size" = 65536;
  ## MEDIA CACHE
  "media.memory_cache_max_size" = 196608;
  "media.memory_caches_combined_limit_kb" = 1572864;
  "media.cache_readahead_limit" = 7200;
  "media.cache_resume_threshold" = 3600;
  ## IMAGE CACHE
  "image.mem.decode_bytes_at_a_time" = 32768;
  ## NETWORK
  "network.buffer.cache.size" = 262144;
  "network.buffer.cache.count" = 128;
  "network.http.max-connections" = 1800;
  "network.http.max-persistent-connections-per-server" = 10;
  "network.http.max-urgent-start-excessive-connections-per-host" = 5;
  "network.websocket.max-connections" = 400;
  "network.http.pacing.requests.min-parallelism" = 12;
  "network.http.pacing.requests.burst" = 20;
  "network.http.connection-retry-timeout" = 0;
  "network.dnsCacheEntries" = 10000;
  "network.dnsCacheExpiration" = 86400;
  "network.dns.max_high_priority_threads" = 8;
  "network.ssl_tokens_cache_capacity" = 32768;
  ## SPECULATIVE CONNECTIONS
  "network.http.speculative-parallel-limit" = 0;
  "network.dns.disablePrefetch" = true;
  "browser.urlbar.speculativeConnect.enabled" = false;
  "browser.places.speculativeConnect.enabled" = false;
  "network.prefetch-next" = false;
  "network.predictor.enabled" = false;
  "network.predictor.enable-prefetch" = false;
  # SECUREFOX
  ## TRACKING PROTECTION
  "browser.contentblocking.category" = "strict";
  "urlclassifier.trackingSkipURLs" = "*.reddit.com, *.twitter.com, *.twimg.com, *.tiktok.com";
  "urlclassifier.features.socialtracking.skipURLs" = "*.instagram.com, *.twitter.com, *.twimg.com";
  "privacy.query_stripping.strip_list" = "__hsfp __hssc __hstc __s _hsenc _openstat dclid fbclid gbraid gclid hsCtaTracking igshid mc_eid ml_subscriber ml_subscriber_hash msclkid oft_c oft_ck oft_d oft_id oft_ids oft_k oft_lk oft_sk oly_anon_id oly_enc_id rb_clickid s_cid twclid vero_conv vero_id wbraid wickedid yclid";
  "browser.uitour.enabled" = false;
  "privacy.globalprivacycontrol.enabled" = true;
  "privacy.globalprivacycontrol.functionality.enabled" = true;
  ## OCSP & CERTS / HPKP
  "security.OCSP.enabled" = 0;
  "security.remote_settings.crlite_filters.enabled" = true;
  "security.pki.crlite_mode" = 2;
  "security.cert_pinning.enforcement_level" = 2;
  ## SSL / TLS
  "security.ssl.treat_unsafe_negotiation_as_broken" = true;
  "security.ssl.require_safe_negotiation" = true;
  "browser.xul.error_pages.expert_bad_cert" = true;
  "security.tls.enable_0rtt_data" = false;
  ## DISK AVOIDANCE
  "browser.privatebrowsing.forceMediaMemoryCache" = true;
  "browser.sessionstore.interval" = 60000;
  "browser.sessionstore.privacy_level" = 2;
  ## SHUTDOWN & SANITIZING
  "privacy.history.custom" = true;
  ## SEARCH / URL BAR
  "browser.search.separatePrivateDefault.ui.enabled" = true;
  "browser.urlbar.update2.engineAliasRefresh" = true;
  "browser.search.suggest.enabled" = true;
  "browser.urlbar.suggest.quicksuggest.sponsored" = false;
  "browser.urlbar.suggest.quicksuggest.nonsponsored" = true;
  "browser.formfill.enable" = false;
  "security.insecure_connection_text.enabled" = true;
  "security.insecure_connection_text.pbmode.enabled" = true;
  "network.IDN_show_punycode" = true;
  ## HTTPS-FIRST POLICY
  "dom.security.https_first" = true;
  ## HTTPS-ONLY MODE
  "dom.security.https_only_mode_error_page_user_suggestions" = true;
  ## PASSWORDS AND AUTOFILL
  "signon.rememberSignons" = false;
  "editor.truncate_user_pastes" = false;
  ## ADDRESS + CREDIT CARD MANAGER
  "extensions.formautofill.addresses.enabled" = false;
  "extensions.formautofill.creditCards.enabled" = false;
  ## MIXED CONTENT + CROSS-SITE
  "network.auth.subresource-http-auth-allow" = 1;
  "security.mixed_content.block_display_content" = true;
  "pdfjs.enableScripting" = false;
  "extensions.postDownloadThirdPartyPrompt" = false;
  "permissions.delegation.enabled" = false;
  ## HEADERS / REFERERS
  "network.http.referer.XOriginTrimmingPolicy" = 2;
  ## CONTAINERS
  "privacy.userContext.ui.enabled" = true;
  ## WEBRTC
  "media.peerconnection.ice.proxy_only_if_behind_proxy" = true;
  "media.peerconnection.ice.default_address_only" = true;
  ## SAFE BROWSING
  "browser.safebrowsing.downloads.remote.enabled" = false;
  ## MOZILLA
  "accessibility.force_disabled" = 1;
  "identity.fxaccounts.enabled" = true;
  "browser.tabs.firefox-view" = true;
  "permissions.default.desktop-notification" = 2;
  "permissions.default.geo" = 2;
  "geo.provider.network.url" = "https://location.services.mozilla.com/v1/geolocate?key=%MOZILLA_API_KEY%";
  "permissions.manager.defaultsUrl" = "";
  "webchannel.allowObject.urlWhitelist" = "";
  ## TELEMETRY
  "toolkit.telemetry.unified" = false;
  "toolkit.telemetry.enabled" = false;
  "toolkit.telemetry.server" = "data:,";
  "toolkit.telemetry.archive.enabled" = false;
  "toolkit.telemetry.newProfilePing.enabled" = false;
  "toolkit.telemetry.shutdownPingSender.enabled" = false;
  "toolkit.telemetry.updatePing.enabled" = false;
  "toolkit.telemetry.bhrPing.enabled" = false;
  "toolkit.telemetry.firstShutdownPing.enabled" = false;
  "toolkit.telemetry.coverage.opt-out" = true;
  "toolkit.coverage.opt-out" = true;
  "datareporting.healthreport.uploadEnabled" = false;
  "datareporting.policy.dataSubmissionEnabled" = false;
  "app.shield.optoutstudies.enabled" = false;
  "browser.discovery.enabled" = false;
  "breakpad.reportURL" = "";
  "browser.tabs.crashReporting.sendReport" = false;
  "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;
  "captivedetect.canonicalURL" = "";
  "network.captive-portal-service.enabled" = false;
  "network.connectivity-service.enabled" = false;
  "app.normandy.enabled" = false;
  "app.normandy.api_url" = "";
  "browser.ping-centre.telemetry" = false;
  "browser.newtabpage.activity-stream.feeds.telemetry" = false;
  "browser.newtabpage.activity-stream.telemetry" = false;
  # PESKYFOX
  ## MOZILLA UI
  "layout.css.prefers-color-scheme.content-override" = 2;
  "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
  "app.update.suppressPrompts" = true;
  "browser.compactmode.show" = true;
  "browser.privatebrowsing.vpnpromourl" = "";
  "extensions.getAddons.showPane" = false;
  "extensions.htmlaboutaddons.recommendations.enabled" = false;
  "browser.shell.checkDefaultBrowser" = false;
  "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
  "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
  "browser.preferences.moreFromMozilla" = false;
  "browser.tabs.tabmanager.enabled" = false;
  "browser.aboutConfig.showWarning" = false;
  "browser.aboutwelcome.enabled" = false;
  "browser.privatebrowsing.enable-new-indicator" = false;
  "cookiebanners.service.mode" = 2;
  "cookiebanners.service.mode.privateBrowsing" = 2;
  "browser.translations.enable" = true;
  ## FULLSCREEN
  "full-screen-api.transition-duration.enter" = "0 0";
  "full-screen-api.transition-duration.leave" = "0 0";
  "full-screen-api.warning.delay" = -1;
  "full-screen-api.warning.timeout" = 0;
  ## URL BAR
  "browser.urlbar.suggest.engines" = false;
  "browser.urlbar.suggest.topsites" = false;
  "browser.urlbar.suggest.calculator" = true;
  "browser.urlbar.unitConversion.enabled" = true;
  ## NEW TAB PAGE
  "browser.newtabpage.activity-stream.feeds.topsites" = false;
  "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
  ## POCKET
  "extensions.pocket.enabled" = false;
  ## DOWNLOADS
  "browser.download.useDownloadDir" = false;
  "browser.download.alwaysOpenPanel" = false;
  "browser.download.manager.addToRecentDocs" = false;
  "browser.download.always_ask_before_handling_new_types" = true;
  ## PDF
  "browser.download.open_pdf_attachments_inline" = true;
  "pdfjs.sidebarViewOnLoad" = 2;
  ## TAB BEHAVIOR
  "browser.tabs.loadBookmarksInTabs" = true;
  "browser.bookmarks.openInTabClosesMenu" = false;
  "browser.menu.showViewImageInfo" = true;
  "findbar.highlightAll" = true;
  # SMOOTHSCROLL
  "apz.overscroll.enabled" = true;
  "general.smoothScroll" = true;
  "general.smoothScroll.msdPhysics.continuousMotionMaxDeltaMS" = 12;
  "general.smoothScroll.msdPhysics.enabled" = true;
  "general.smoothScroll.msdPhysics.motionBeginSpringConstant" = 600;
  "general.smoothScroll.msdPhysics.regularSpringConstant" = 650;
  "general.smoothScroll.msdPhysics.slowdownMinDeltaMS" = 25;
  "general.smoothScroll.msdPhysics.slowdownMinDeltaRatio" = 2.0;
  "general.smoothScroll.msdPhysics.slowdownSpringConstant" = 250;
  "general.smoothScroll.currentVelocityWeighting" = 1.0;
  "general.smoothScroll.stopDecelerationWeighting" = 1.0;
  "mousewheel.default.delta_multiplier_y" = 200; # 250-400

  # CUSTOM
  ## typeahead find
  "accessibility.typeaheadfind" = false;
  "accessibility.typeaheadfind.autostart" = true;
  "accessibility.typeaheadfind.linksonly" = true;
  "accessibility.typeaheadfind.startlinksonly" = true;
  "accessibility.typeaheadfind.casesensitive" = 0;

  "browser.backspace_action" = 0;

  "xpinstall.signatures.required" = false;

  "general.config.sandbox_enabled" = false;

  "browser.theme.content-theme" = 0;
  "browser.theme.toolbar-theme" = 0;
  "devtools.theme" = "dark";
  ## Before BetterFox
  "dom.enable_web_task_scheduling" = true;
  "browser.autofocus" = false;
  "browser.onboarding.enabled" = false;
  #"browser.pagethumbnails.capturing_disabled" = true;
  #"browser.pocket.api" = "";
  #"browser.pocket.oAuthConsumerKey" = "";
  #"browser.pocket.site" = "";
  "browser.toolbars.bookmarks.visibility" = "never";
  "browser.send_pings" = false;
  "browser.send_pings.require_same_host" = true;
  #"browser.startup.page" = 3;
  "browser.tabs.closeWindowWithLastTab" = true;
  "media.autoplay.default" = 1;
  #"ui.key.menuAccessKeyFocuses" = false;
  "onebar.hide-all-URLbar-icons" = true;
  "onebar.hide-navigation-buttons" = true;
  "browser.ctrlTab.sortByRecentlyUsed" = true;
  "browser.engagement.ctrlTab.has-used" = true;
  # XDG desktop portal
  "widget.use-xdg-desktop-portal.file-picker" = 1;
  "widget.use-xdg-desktop-portal.mime-handler" = 1;
  "widget.use-xdg-desktop-portal.settings" = 1;
  "widget.use-xdg-desktop-portal.location" = 1;
  "widget.use-xdg-desktop-portal.open-uri" = 1;
}
