#!/bin/env node

import { Command, Argument, Option } from 'commander'
import { execSync } from 'child_process'

const program = new Command()

program
  .name('identus-test')
  .description('CLI for identus-test suite setup')

const ownerOpt = () => {
  return new Option(
    '-o, --owner <owner>',
    'the github owner of the releases repo to draw versions from'
  )
    .default('input-output-hk')
}

const repoOpt = () => {
  return new Option(
    '-r, --repo <repo>',
    'the name of github releases repo to draw versions from'
  )
    .default('atala-releases')
}

program.command('query')
  .description('query the version of a particular component')
  .addArgument(
    new Argument('<component>', 'the component whose version to query')
      .choices([
        'cloud-agent',
        'mediator',
        'prism-node',
        // sdk
        'sdk-typescript',
        'sdk-swift',
        'sdk-kmm',
        // other
        'apollo',
        'doc'
      ])
  )
  .addArgument(
    new Argument('[version]', 'the identus release')
      .default('2.12')
  )

  .addOption(ownerOpt())
  .addOption(repoOpt())
  .action((component, version, options) => {
    const result = execSync([
      './bin/query.sh',
      '--owner', options.owner,
      '--repo', options.repo,
      '--version', version,
      `--component "${component.replace('-', ' ')}"`
    ].join(' '))

    console.log(result.toString())
  })


program.command('up')
  .description('spin up a test setup of the particular identus version (requires docker compose)')
  .addArgument(
    new Argument('<version>', 'the identus release')
  )
  .addOption(ownerOpt())
  .addOption(repoOpt())
  .action((component, version, options) => {
    console.log('coming soon')

    // 1. make a folder for version

    // 2. fetch specified versions of
    //   - mediator
    //   - cloud-agent
    
    // 3. clone repos in e.g.
    //   git clone https://github.com/input-output-hk/atala-prism-mediator.git --branch identus-mediator-v0.14.2 --depth 1
    
    // TODO: think about
    // - [ ] is it safer to assume docker-compose may change over time?
    //    - /releases/2.12/mediator + /releases/2.12/cloud-agent
    //    - /releases/2.13/mediator + /releases/2.13/cloud-agent
    //      
    // - [ ] where we should clone these files
    //    - [ ] /tmp/identus-test/... ?? (not ideal for offline-first)
    //    - [x] ~/.identus-test/...
    //      - YES, global cache
    //      - but use https://www.npmjs.com/package/env-paths
    //    - [ ] node_modules/identus-test/releases/2.12/
    //    
    // - [ ] minimal clone / copy?
    //    - we only really need docker-compose.yml .... and any other files referenced D:
    //    - git clone --depth 1
    //    - rm -rf .git
    //    - :D

  })

program.command('down')
  .description('spin down a test setup of the particular identus version (requires docker compose)')
  .addArgument(
    new Argument('<version>', 'the identus release')
  )
  .addOption(ownerOpt())
  .addOption(repoOpt())
  .action((component, version, options) => {
    console.log('coming soon')
  })


program.parse()
