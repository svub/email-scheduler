class EmailScheduler
  constructor: ->
    @jobs = []
    @queue = new Meteor.Collection 'EmailSchedulerCollection'
    @tz = 'Europe/Athens'
    @Fiber = Npm.require 'fibers'

  run: (name, composer) ->
    log "EmailScheduler.run #{name} at #{moment().format()}..."
    for userId, messages of _.groupBy (@load name),'userId'
      @send composer messages, userId, name
      #@queue.update { _id: userId }, $set: done: true
    @remove name
  load: (schedule) -> (@queue.find schedule: schedule, done: $exists: 0).fetch()
  #remove: (schedule) -> (@queue.remove { schedule: schedule }, { multi: true })
  remove: (schedule) -> @queue.update { schedule: schedule }, { $set: done: new Date() }, multi: true
  send: (composedMessage) -> @sendEmail m.address, m.subject, m.content if (m=composedMessage)?
  add: (schedule, user, data) -> @queue.insert schedule: schedule, data: data, userId: user?._id ? user

  addSchedule: (name, pattern, composer = @getComposer()) ->
    # meteor-cron2 based scheduling
    #try
    #  log "EmailScheduler: adding schedule #{name} with pattern #{pattern}..."
    #  @jobs.push job = new CRON.CronJob pattern, (=> @Fiber(=> @run name, composer, job, pattern).run()), null, true, @tz
    #  true
    #catch e
    #  log "EmailScheduler: invalid pattern '#{pattern}' for schedule '#{name}'"
    #  loge e
    #  false
    log 'mooooo'
    SyncedCron.add
      name: name
      schedule: (parser) -> # parser is a later.parse object
        logmr 'EmailScheduler.addSchedule: parsed schedule', parser.cron pattern
      job: => @run name, composer
    @_autoStartScheduler()

  _autoStartScheduler: debounce 1000, -> @Fiber(=> @startScheduler()).run()
  startScheduler: ->
    if @started then log 'EmailScheduler: scheduler started already.'
    else
      @started = true
      Meteor.startup ->
        log 'EmailScheduler: starting scheduler...'
        SyncedCron.start()

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
