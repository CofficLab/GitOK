const cp = require('child_process')
const util = require('util')

const childOptions = {
  shell: 'bash',
  stdio: 'inherit'
}

const exec = util.promisify(cp.exec)

;(async () => {
  await Promise.all([
    cp.exec('cd packages/client/ && npm run build', childOptions),
    cp.exec('cd packages/vsc_extension/ && npm run build', childOptions)
  ])
  cp.execSync('cd packages/vsc_extension/ && npm run dev:vscode', childOptions)
})()
