(async () => {
  const V = JSON.parse(localStorage.getItem('fatcamp.v2') || '{}');
  const a = V.auth;
  if (!a || !a.token) return console.log('Not signed in in this tab — open the app and sign in first.');
  const U = 'https://chghvwnytjlakuvkkluv.supabase.co';
  const K = 'sb_publishable_H69bdgZ5FdZIojX5LHK3aQ_2Vz2CZif';
  const g = async p => (await fetch(U + p, { headers: { apikey: K, Authorization: 'Bearer ' + a.token } })).json();

  const S  = await g('/rest/v1/sessions?select=done_at,xp,title,coverage,minutes,effort&order=done_at.desc');
  const St = await g('/rest/v1/standings?select=*&lifter=eq.' + a.uid);
  const me = St[0] || null;
  const sum = S.reduce((t, r) => t + r.xp, 0);

  console.log('%c--- sessions the server has ---', 'font-weight:bold');
  console.table(S.slice(0, 12));
  console.log('%c--- your standings row ---', 'font-weight:bold', me);

  if (!me) return console.log('%cNO STANDINGS ROW — the trigger did not fire.', 'color:#e00;font-weight:bold');

  const wk = S.filter(r => Date.now() - new Date(r.done_at) < 7 * 864e5).reduce((t, r) => t + r.xp, 0);
  [['total_xp equals the sum of your sessions', me.total_xp === sum,      me.total_xp + ' vs ' + sum],
   ['session count matches',                    me.sessions === S.length, me.sessions + ' vs ' + S.length],
   ['week_xp matches last 7 days',              me.week_xp === wk,        me.week_xp + ' vs ' + wk],
   ['handle published',                         !!me.handle,              me.handle],
   ['streak computed',                          me.streak > 0,            me.streak + ' day(s)'],
   ['region set',                               !!me.region,              me.region || '(none)']
  ].forEach(([n, ok, d]) => console.log(ok ? '%c PASS ' : '%c FAIL ',
      'background:' + (ok ? '#1F8A52' : '#D8382B') + ';color:#fff', n, '—', d));
})()
