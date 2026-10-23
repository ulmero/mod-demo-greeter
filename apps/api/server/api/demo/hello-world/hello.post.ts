import { sayHello } from '../../../lib/hello-world'

// A POST, because saying hello changes the count. A GET must not change data.
export default defineFeatureHandler('demo.hello-world', async (_feat, event) => {
  const scope = requireAccess(event, 'Demo.HelloWorld')
  if (!scope) throw createError({ statusCode: 401, message: 'Authentication required' })
  return await sayHello(scope.accountId)
})
