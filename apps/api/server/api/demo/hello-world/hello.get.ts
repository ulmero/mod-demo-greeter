import { readGreetings } from '../../../lib/hello-world'

export default defineFeatureHandler('demo.hello-world', async (_feat, event) => {
  const scope = requireAccess(event, 'Demo.HelloWorld')
  if (!scope) throw createError({ statusCode: 401, message: 'Authentication required' })
  return await readGreetings(scope.accountId)
})
