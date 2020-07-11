'use strict'

const Yang = require('..');
const Schema = require('./ietf-yang-library@2016-06-21.yang');
const crypto = require('crypto');

module.exports = Schema.bind({

  '/yanglib:modules-state': {
    get: async (ctx) => {
      const modules = Yang.module.map(module => {
	const { namespace, revision=[], feature=[], include=[] } = module;
	return {
          name: module.tag,
          namespace: (namespace ? namespace.tag : ''),
          revision:  (revision[0] ? revision[0].tag : ''),
          feature:   feature.map(x => x.tag),
          'conformance-type': 'implement',
          submodule: include.map(x => ({
            name: x.tag,
            revision: x['revision-date'] ? x['revision-date'].tag : ''
          })),
	};
      });
      const keys = modules.map(x => x.name);
      const hash = crypto.createHash('md5').update(keys.join(',')).digest('hex');
      if (!hash) return ctx.data;
      
      const prev = ctx.data ? ctx.get('module-set-id') : undefined
      if (hash !== prev) {
	// TODO: notification yang-library-change
	ctx.logDebug("trigger yang-library-change notification", keys);
      }
      ctx.data = {
	'module-set-id': hash,
	module: modules
      }
      return ctx.data;
    }
  },

});
