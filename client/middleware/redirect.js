export default function ({ redirect, route }) {
  if (route.name === 'index') {
    return redirect('/go/jaragua')
  }
}
