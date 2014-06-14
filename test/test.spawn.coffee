# vi: set foldmethod=marker
mongoose = require 'mongoose'
Models = require 'app/models'
User = Models.User
Booking = Models.Booking
db = require 'test/db'
assert = require 'assert'

userSeeds = require 'test/seeds/users'
bookingSeeds = require 'test/seeds/bookings'
postSeeds = require 'test/seeds/posts'

# Shared test hooks ##################################################

crrtUser = null# {{{

[lawrence, luke, satya, mike] = [
  userSeeds.lawrence
  userSeeds.luke
  userSeeds.satya
  userSeeds.mike
]

# Seed database before each test
beforeEach (done) ->
  User.register lawrence(), 'password', (err, user) -># {{{
    user?.fail? 'could not seed Lawrence'
    crrtUser = user
    User.register mike(), 'password', (err, user) ->
      user?.fail? 'could not seed Mike'
      do done# }}}

# Clear model after every test
afterEach (done) ->
  User.model.remove {}, -> Booking.model.remove {}, -> do done# }}}

# UserModel Specs ####################################################

describe 'UsersModel', ->

  # Seed database before each test
  beforeEach (done) ->
    User.model.findOne email: lawrence().email, (err, user) -># {{{
      user?.fail? 'could not find user'
      crrtUser = user
      do done# }}}

  describe 'on register', ->

    newUser = null# {{{

    beforeEach (done) ->
      User.register luke(), 'password', (err, user) -># {{{
        err?.fail? 'failed to seed database'
        newUser = user
        do done# }}}

    afterEach (done) ->
      User.model.remove email: 'luke.mccrone12@ic.ac.uk', -> do done

    it 'should create a new user document', ->
      newUser.email.should.equal 'luke.mccrone12@ic.ac.uk'# {{{
      newUser.fname.should.equal 'Luke'
      newUser.lname.should.equal 'McCrone'
      newUser.pic.should.equal '/img/test/luke.jpg'# }}}

    it 'should generate random salt for user.auth.salt', ->
      newUser.auth.salt.length.should.be.above 10

    it 'should not allow duplicate emails', (done) ->
      user = satya()# {{{
      user.email = luke().email
      User.register user, 'password', (err, user) ->
        user?.should.fail? 'user should not exist'
        err.should.be.ok
        err.code.should.equal 11000
        do done# }}}# }}}

  describe 'provides security that', ->

    it 'authenticates registered users', (done) -># {{{
      authed = User.model.auth lawrence().email, 'password'# {{{
      authed.then (user) ->
        user.should.be.ok
        user.email.should.equal lawrence().email
        do done
      authed.catch done# }}}

    it 'rejects unregistered users', (done) ->
      authed = User.model.auth 'idontexist@domain.com', 'password'# {{{
      authed.then (user) ->
        done new Error 'should not have authorized bad user'
      authed.catch -> do done# }}}

    it 'rejects bad email/password', (done) ->
      authed = User.model.auth lawrence().email, 'badpassword'# {{{
      authed.then (user) ->
        done new Error 'should not have authorized bad password'
      authed.catch -> do done# }}}# }}}

  describe 'generates tokens', ->

    it 'generates tokens for correct passwords', (done) ->
      json = crrtUser.genToken 'password'# {{{
      json.then (data) ->
        data.token.should.be.ok
        data.token.should.be.a.String
        data.user.email.should.equal crrtUser.email
        do done
      json.catch done# }}}

  describe 'rejects token requests for', ->

    it 'bad passwords', (done) ->
      json = crrtUser.genToken 'badpassword'# {{{
      json.then -> done 'should not produce token for bad password'
      json.catch -> do done# }}}

  describe 'produces JSON for API', ->

    Object.keys(User.formats).map (v) ->
      it "version #{v}", (done) ->
        User.model.findOne email: lawrence().email, (err, user) -># {{{
          user.should.be.ok
          json = user.api v
          json.email.should.equal lawrence().email
          json.should.have.properties [
            '_meta', 'email', 'fname'
            'lname', 'pic', 'profile'
          ]
          do done# }}}

describe 'BookingsModel', ->

  Booking = Models.Booking
  [dogWalking, mathsTutoring] = [
    bookingSeeds.dogWalking
    bookingSeeds.mathsTutoring
  ]
  dogBooking = null

  # Seed database before each test
  beforeEach (done) ->
    Booking.create dogWalking(), (err, booking) -># {{{
      err?.fail 'failed to seed database'
      dogBooking = booking
      do done# }}}

  describe 'on new booking', ->

    it 'should create new booking', (done) -># {{{
      Booking.create mathsTutoring(), (err, booking) -># {{{
        err?.fail()
        booking.should.be.ok
        booking.bid.should.be.ok
        for own k,v of mathsTutoring()
          booking[k].should.eql v if typeof v is not 'object'
        do done# }}}

    it 'should identify bookings by bid or _id', ->
      dogBooking._id.should.equal dogBooking.bid# }}}

  describe 'on posting', ->

    describe 'should accept posts from', ->

      beforeEach (done) -># {{{
        User.register satya(), 'password', (err, user) -># {{{
          err?.fail? 'failed to seed Satya'
          do done# }}}

      it 'solver', (done) ->
        dogBooking.canPost dogBooking.solver# {{{
        .then -> do done
        .catch done# }}}

      it 'booker', (done) ->
        dogBooking.canPost dogBooking.booker# {{{
        .then -> do done
        .catch done# }}}# }}}

    describe 'should deny access to', ->

      it 'invalid user', (done) ->
        dogBooking.canPost 'invalid@domain.com'# {{{
        .then -> fail 'should not allow invalid user to post'
        .catch done# }}}

      it 'unrelated user', (done) ->
        dogBooking.canPost lawrence().email# {{{
        .then -> fail 'should not allow unrelated user to post'
        .catch done# }}}

  describe 'on creating new post', (done) ->


    beforeEach (done) ->
      User.register satya(), 'password', (err, user) -># {{{
        err?.fail? 'failed to seed Satya'
        do done# }}}

    describe 'should add to posts', ->

      it 'comment', (done) ->
        [email, ptype, value, posted] = postSeeds.comment# {{{
        dogBooking.post(postSeeds.comment...)
        .then (booking) ->
          [prev..., post] = booking.posts.sort (a,b) -> a.posted - b.posted
          post.should.have.properties 'posted', 'ptype', 'user', 'value'
          post.value.should.be.type 'string'
          post.should.eql
            user: email, posted: posted, ptype: ptype, value: value
          do done
        .catch done# }}}

  describe 'produces JSON for API', ->

    it "version 1A", (done) ->
      Booking.model.find {}, (err, bookings) -># {{{
        for booking in bookings.map((b) -> b.api '1A')
          booking.should.be.ok
          booking.should.have.properties [
            'bid', 'booker', 'solver', 'requested'
            'accepted', 'cancelled', 'start', 'end', 'task'
            'hourly', 'expenses', 'location', 'summary', 'posts'
          ]
          do done# }}}
        


