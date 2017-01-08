import { Readable } from 'stream'
import { inspect } from 'util'
import Promise from 'bluebird'
import readline from 'readline'
import execa from 'execa'
import noop from 'lodash/noop'
import first from 'lodash/first'
import _debug from 'debug'
import _debugStream from 'debug-stream'

const debug = _debug('database')
const debugStream = _debugStream(debug)

const defaultOptions = {
  executePath: './eazydb'
}

function defer () {
  let res, rej
  const promise = new Promise((resolve, reject) => {
    res = resolve
    rej = reject
  })
  return {
    resolve: res,
    reject: rej,
    promise: promise
  }
}

export class Database {
  constructor (options) {
    const stdin = new Readable()
    stdin._read = noop
    this._stdin = stdin
    this._queue = []
    this._pending = false
    this._options = Object.assign({}, defaultOptions, options)
    this._instance = execa(this._options.executePath, {
      input: this._stdin.pipe(debugStream('stdin: %s'))
    })
  }

  connect () {
    this._stdout = readline.createInterface({
      input: this._instance.stdout.pipe(debugStream('stdout: %s'))
    })
    this._stdout.on('line', (line) => {
      debug('Get response: (%s)', line)
      if (line) {
        this._processResponse(JSON.parse(line))
      }
    })
    return this
  }

  use (database) {
    debug('Use %s', database)
    return this._push({
      command: `use ${database}`,
    })
  }

  create (path, schema) {
    debug('Create %s', path)
    return this._push({
      command: 'create',
      arg: {
        path,
        schema
      }
    })
  }

  get (id) {
    debug('Get %s', id)
    return this._push({
      command: 'get',
      arg: {
        id
      }
    })
  }

  insert (data) {
    debug('Insert: %s', inspect(data))
    return this._push({
      command: 'insert',
      arg: data
    })
  }

  delete (id) {
    debug('Delete: %s', id)
    return this._push({
      command: 'delete',
      arg: {
        id
      }
    })
  }

  update (id, value) {
    debug('Update %s: %s', id, inspect(value))
    return this._push({
      command: 'update',
      arg: {
        id,
        value
      }
    })
  }

  close () {
    this._push({
      command: 'exit'
    })
    return Promise.resolve()
  }

  _push (data) {
    debug(`Push: ${JSON.stringify(data)}`)
    const defered = defer()
    this._queue.push({ ...data, defered })
    this._processQueue()
    return defered.promise
  }

  _processQueue () {
    debug('Process queue')
    if (this._pending) {
      debug('Processing pending')
      return
    }
    if (this._queue.length) {
      this._pending = true
      const { command, arg } = first(this._queue)
      debug('Queue not empty')
      if (arg) {
        this._send(`${command} ${JSON.stringify(arg)}\n`)
      } else {
        this._send(`${command}\n`)
      }
    }
  }

  _send (command) {
    debug(`Send: ${command}`)
    this._stdin.push(`${command}\n`)
    this._stdin.resume()
  }

  _processResponse(response) {
    if (!this._pending) {
      throw Error('No pending command')
    }
    first(this._queue).defered.resolve(response)
    this._queue.splice(0)
    this._pending = false
    this._processQueue()
  }

  static open (options = defaultOptions) {
    return new Promise((resolve) => {
      const database = new Database(options)
      resolve(database.connect())
    })
  }
}
