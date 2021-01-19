plugin_paths = { "/usr/share/jitsi-meet/prosody-plugins/" }

-- domain mapper options, must at least have domain base set to use the mapper
muc_mapper_domain_base = "{{ meet_domain }}";

{% if turn_enabled is defined and turn_enabled %}
turncredentials_secret = "{{ turn_secret }}";

turncredentials = {
  { type = "turns", host = "{{ meet_domain }}", port = "5349", transport = "tcp" }
};
{% endif %}

cross_domain_bosh = false;
consider_bosh_secure = true;
-- https_ports = { }; -- Remove this line to prevent listening on port 5284

-- https://ssl-config.mozilla.org/#server=haproxy&version=2.1&config=intermediate&openssl=1.1.0g&guideline=5.4
ssl = {
  protocol = "tlsv1_2+";
  ciphers = "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384"
}

VirtualHost "{{ meet_domain }}"
        -- enabled = false -- Remove this line to enable this host
{% if xmpp_auth == "token" %}
        authentication = "token"
        app_id="{{ token_auth_appid }}"
        app_secret="{{ token_auth_appsecret }}"
        allow_empty_token = false
        allow_unencrypted_plain_auth = true
{% elif xmpp_auth == "ldap" %}
        authentication = "cyrus"
        cyrus_application_name = "xmpp"
        allow_unencrypted_plain_auth = true
{% else %}
        authentication = "anonymous"
{% endif %}
        -- Properties below are modified by jitsi-meet-tokens package config
        -- and authentication above is switched to "token"
        --app_id="example_app_id"
        --app_secret="example_app_secret"
        -- Assign this host a certificate for TLS, otherwise it would use the one
        -- set in the global section (if any).
        -- Note that old-style SSL on port 5223 only supports one certificate, and will always
        -- use the global one.
        ssl = {
                key = "/etc/prosody/certs/{{ meet_domain }}.key";
                certificate = "/etc/prosody/certs/{{ meet_domain }}.crt";
        }
        speakerstats_component = "speakerstats.{{ meet_domain }}"
        conference_duration_component = "conferenceduration.{{ meet_domain }}"
        -- we need bosh
        modules_enabled = {
            "bosh";
            "pubsub";
            "ping"; -- Enable mod_ping
            "speakerstats";
{% if turn_enabled is defined and turn_enabled %}
            "turncredentials";
{% else %}
            -- "turncredentials";
{% endif %}
            "conference_duration";
            "muc_lobby_rooms";
{% if xmpp_auth == "ldap" %}
	    "auth_cyrus";
{% endif %}
{% if enable_recording and add_participants_metadata  %}
            "presence_identity";
{% endif %}
        }
        c2s_require_encryption = false
        lobby_muc = "lobby.{{ meet_domain }}"
        main_muc = "conference.{{ meet_domain }}"
{% if groups['jibris'] | length > 0 %}
        muc_lobby_whitelist = { "recorder.{{ meet_domain }}" } -- Here we can whitelist jibri to enter lobby enabled rooms
{% endif %}

{% if allow_guests %}
VirtualHost "guest.{{ meet_domain }}"
    authentication = "anonymous"
    c2s_require_encryption = false

{% endif %}
Component "conference.{{ meet_domain }}" "muc"
    storage = "memory"
    modules_enabled = {
        "muc_meeting_id";
        "muc_domain_mapper";
{% if xmpp_auth == "token" %}
        "token_verification";
	"token_moderation";
{% endif %}
    }
    admins = { "{{ jicofo_user }}@auth.{{ meet_domain }}" }
    muc_room_locking = false
    muc_room_default_public_jids = true

-- internal muc component
Component "internal.auth.{{ meet_domain }}" "muc"
    storage = "memory"
    modules_enabled = {
      "ping";
    }
    admins = { "{{ jicofo_user }}@auth.{{ meet_domain }}" }
    muc_room_locking = false
    muc_room_default_public_jids = true

VirtualHost "auth.{{ meet_domain }}"
    ssl = {
        key = "/etc/prosody/certs/auth.{{ meet_domain }}.key";
        certificate = "/etc/prosody/certs/auth.{{ meet_domain }}.crt";
    }
    authentication = "internal_plain"

{% if groups['jibris'] | length > 0 %}
VirtualHost "recorder.{{ meet_domain }}"
    modules_enabled = {
      "ping";
    }
    authentication = "internal_plain"

{% endif %}
Component "focus.{{ meet_domain }}"
    component_secret = "{{ jicofo_secret }}"

Component "speakerstats.{{ meet_domain }}" "speakerstats_component"
    muc_component = "conference.{{ meet_domain }}"

Component "conferenceduration.{{ meet_domain }}" "conference_duration_component"
    muc_component = "conference.{{ meet_domain }}"

Component "lobby.{{ meet_domain }}" "muc"
    storage = "memory"
    restrict_room_creation = true
    muc_room_locking = false
    muc_room_default_public_jids = true
