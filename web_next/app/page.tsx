import { createClient } from '@/utils/supabase/server'
import { cookies } from 'next/headers'

export default async function Page() {
  const cookieStore = cookies()
  const supabase = createClient(cookieStore)

  const { data: todos, error } = await supabase.from('todos').select('*')
  if (error) {
    console.error('Supabase error', error)
  }

  return (
    <ul>
      {Array.isArray(todos) && todos.length > 0 ? (
        todos.map((todo: any) => (
          <li key={todo.id}>{todo.title ?? JSON.stringify(todo)}</li>
        ))
      ) : (
        <li>No todos</li>
      )}
    </ul>
  )
}
