#
class EmailScheduler
	constructor: ->
		@jobs = []
		@queue = new Meteor.Collection 'EmailSchedulerCollection'
		@tz = 'Europe/Athens'
		@Fiber = Npm.require 'fibers'

	run: (name, composer) ->
		log "EmailScheduler.run #{name}..."
		@send composer messages, id, name for id, messages of _.groupBy (@load name),'userId'
		@remove name
	load: (schedule) -> (@queue.find schedule: schedule).fetch()
	remove: (schedule) -> (@queue.remove { schedule: schedule }, { multi: true })
	send: (composedMessage) -> @sendEmail m.address, m.subject, m.content if (m=composedMessage)?
	add: (schedule, user, data) -> @queue.insert schedule: schedule, data: data, userId: user?._id ? user

	addSchedule: (name, pattern, composer = @getComposer()) ->
		try
			log "EmailScheduler: adding schedule #{name} with pattern #{pattern}..."
			#fiber = @Fiber.current
			#@jobs.push job = new CRON.CronJob pattern, (=> @run name, composer, job, pattern), (-> fiber.run()), true, @tz
			#@jobs.push job = new CRON.CronJob pattern, (-> Meteor.call 'emailschedulerrun', name, composer, job, pattern), (-> fiber.run()), true, @tz
			@jobs.push job = new CRON.CronJob pattern, (=> @Fiber(=> @run name, composer, job, pattern).run()), null, true, @tz
			#@Fiber.yield()
			true
		catch e
			log "EmailScheduler: invalid pattern '#{pattern}' for schedule '#{name}'"
			loge e
			false

	configure: (config) -> _.extend @, config
	# properties and methods below configurable, i.e. should be overwritten as needed
	from: 'not@configur.ed'
	replyTo: undefined # @from if undefined
	subject: undefined # composer(...).subject if undefined
	getComposer: -> (messages, userId, schedule) => # default composer mostly for testing than for production use
		address: @getAddress userId
		subject: @subject ? schedule
		content: (JSON.stingify messages for m in messages).join '\n\n'
	getAddress: (userId) -> (Meteor.user.findOne _id: userId)?.profile?.email
	sendEmail: (address, subject, content) ->
		logr "EmailScheduler.sendEmail to #{address} about #{subject}", content
		Email.send
			to: address
			from: @from
			replyTo: @replyTo ? @from
			subject: subject
			html: content

Meteor.emailScheduler ?= new EmailScheduler()
