Package.describe({
	summary: "Sends out scheduled emails e.g. for newsletters or updates."
});

Package.on_use(function (api, where) {
	api.use(['underscore', 'moment', 'coffeescript', 'underscore-string-latest', 'meteor', 'templating', 'ejson', 'deps', 'tools', 'meteor-cron2'], 'server');
	api.add_files('server/emailscheduler.coffee', 'server');
});
