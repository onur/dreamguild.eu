
var DreamGuild = {

  update_server_time: function () {
    var now = new Date ();
    var now_utc = new Date(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(),  now.getUTCHours() + 2, now.getUTCMinutes(), now.getUTCSeconds());
    var hour = now_utc.getHours ();
    var min = now_utc.getMinutes ();
    var second = now_utc.getSeconds ();
    if (hour < 10) hour = '0' + hour;
    if (min < 10) min = '0' + min;
    if (second < 10) second = '0' + second;
    $('#server-time').text (hour + ':' + min + ':' + second);
    setTimeout (DreamGuild.update_server_time, 1000);
  }

};
