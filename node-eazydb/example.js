import EazyDB from './lib'
import path from 'path'

const executePath = path.resolve(path.join(__dirname, '..', 'bin', 'eazydb'))

EazyDB.open({ executePath }).then((db) => {
  console.log('Open')
  db.use('../db/num-db').then(() => {
    console.log('Success')
    return db.dump()
  }).then((data) => {
    console.dir(data)
    return db.close()
  }).then(() => {
    console.log('Database close')
  })
})
