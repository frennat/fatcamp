/* author-poses — keypose authoring for ARCH, outside the app.
 *
 * A keypose is authored as anchors (pelvis, shoulder, head, wrist, ankle,
 * toe) plus bow hints for the elbow and knee; this tool solves the in-between
 * joints with the same segment lengths the app enforces and emits finished
 * J(...) lines. It exists because IK in the Blender rig flips its pole plane
 * outside the standing configuration it was tuned in — a racked bar or a
 * lying press puts elbows above heads — while a two-bone solve with an
 * explicit bow direction is deterministic everywhere. The rig remains the
 * place to LOOK at a pose; numbers are authored here.
 *
 * Canvas space: y grows down, floor at 220, 100 units = 1 m, figure faces +x.
 * Joint order: head neck shoulder elbow wrist hip pelvis knee ankle toe.
 *
 *   node tools/author-poses.mjs            # solve + print all specs
 */

const SEG = {torso:60, head:20, neck2sh:9.5, uarm:28, farm:28, pel2hip:5, thigh:51, shin:46, foot:15};

const norm = (v) => { const l = Math.hypot(v[0], v[1]) || 1; return [v[0]/l, v[1]/l]; };
const add = (a, b, k = 1) => [a[0] + b[0]*k, a[1] + b[1]*k];
const sub = (a, b) => [a[0] - b[0], a[1] - b[1]];

/* two-bone solve: joint between a and c, bones l1/l2, bowed toward `hint` */
function bone2(a, c, l1, l2, hint){
  const d = sub(c, a), L = Math.hypot(d[0], d[1]);
  if(L >= l1 + l2 - 0.5){                     /* straight (or out of reach) */
    return add(a, norm(d), l1);
  }
  const t = (l1*l1 - l2*l2 + L*L) / (2*L);
  const h = Math.sqrt(Math.max(0, l1*l1 - t*t));
  const dir = norm(d), mid = add(a, dir, t);
  const p1 = add(mid, [ dir[1], -dir[0]], h);
  const p2 = add(mid, [-dir[1],  dir[0]], h);
  const dot = (p) => (p[0]-mid[0])*hint[0] + (p[1]-mid[1])*hint[1];
  return dot(p1) >= dot(p2) ? p1 : p2;
}

/* one keypose spec -> the 10 solved joints, app-consistent */
export function solveKey(S){
  const spineUp = norm(sub(S.shoulder, S.pelvis));
  const neck = add(S.shoulder, spineUp, SEG.neck2sh);
  const head = add(neck, norm(sub(S.head, neck)), SEG.head);
  const hip = add(S.pelvis, spineUp, SEG.pel2hip);
  const knee = S.knee || bone2(hip, S.ankle, SEG.thigh, SEG.shin, S.kneeHint || [1, 0]);
  const elbow = S.elbow || bone2(S.shoulder, S.wrist, SEG.uarm, SEG.farm, S.elbowHint || [1, 0]);
  const J = [head, neck, S.shoulder, elbow, S.wrist, hip, S.pelvis, knee, S.ankle, S.toe];
  return J.map(p => [Math.round(p[0]), Math.round(p[1])]);
}

export const jline = (J) => "J(" + J.map(p => p[0] + "," + p[1]).join(", ") + ")";

/* semantic report so a bad pose is caught before it teaches bad form */
export function report(name, J){
  const [hd, nk, sh, el, wr, hip, pv, kn, an, to] = J;
  const mid = ((an[0] + to[0]) / 2).toFixed(0);
  return `${name}: bar_x=${wr[0]} midfoot=${mid} knee_x=${kn[0]} toe_x=${to[0]}` +
         ` hip=(${pv[0]},${pv[1]}) sh=(${sh[0]},${sh[1]})`;
}

/* ------------------------------------------------------------------ specs */
/* Feet planted for standing sagittal archetypes */
const FEET = {ankle: [97, 212], toe: [111, 218]};

export const SPECS = {
  /* High-bar back squat. Bar rides the shoulder, so shoulder x IS bar x and
     stays over mid-foot the whole way; hips break back first, knees track
     forward past the toes at depth (that is what high-bar ankles do), bottom
     just below parallel, torso ~34 deg. Hands grip the bar beside the
     shoulder — authored as fixed world offsets, not solved. */
  squat: [
    {pelvis:[99,115], shoulder:[97,59],  head:[98,32],   elbow:[86,74],  wrist:[93,57],  ...FEET, kneeHint:[1,0]},
    {pelvis:[73,148], shoulder:[103,95], head:[117,70],  elbow:[92,110], wrist:[99,93],  ...FEET, kneeHint:[1,0]},
    {pelvis:[70,176], shoulder:[105,125],head:[121,102], elbow:[94,140], wrist:[101,123],...FEET, kneeHint:[1,0]},
  ],
  /* Front squat: bar on the front delts, elbows HIGH (upper arm near
     horizontal — the rack collapses if they drop), torso far more upright
     than the back squat, knees travel further forward. */
  frontsquat: [
    {pelvis:[100,115], shoulder:[99,59],  head:[100,32], elbow:[125,67],  wrist:[110,58],  ...FEET, kneeHint:[1,0]},
    {pelvis:[80,146],  shoulder:[97,89],  head:[105,63], elbow:[123,97],  wrist:[108,88],  ...FEET, kneeHint:[1,0]},
    {pelvis:[78,175],  shoulder:[99,119], head:[108,92], elbow:[125,127], wrist:[110,118], ...FEET, kneeHint:[1,0]},
  ],
  /* Overhead press: bar starts on the clavicle, arcs AROUND the face (hips
     nudge forward, head retreats), finishes stacked over the shoulder with
     the head "through the window" and a hint of shrug. */
  ohp: [
    {pelvis:[100,115], shoulder:[100,58], head:[100,32], elbow:[112,83], wrist:[102,66], ...FEET, kneeHint:[1,0]},
    {pelvis:[104,115], shoulder:[99,58],  head:[95,34],  wrist:[104,34], elbowHint:[1,0], ...FEET, kneeHint:[1,0]},
    {pelvis:[101,115], shoulder:[100,55], head:[102,30], wrist:[100,0],  elbowHint:[1,0], ...FEET, kneeHint:[1,0]},
  ],
  /* Bench: the body is a set platform — only the bar moves. Touch low on the
     chest, J-curve up-and-back, lockout stacked over the shoulder. */
  bench: [
    {pelvis:[126,152], shoulder:[82,145], head:[58,138], elbow:[97,142], wrist:[86,137],
     ankle:[146,208], toe:[160,214], kneeHint:[0.4,-1]},
    {pelvis:[126,152], shoulder:[82,145], head:[58,138], wrist:[85,112], elbowHint:[1,-0.2],
     ankle:[146,208], toe:[160,214], kneeHint:[0.4,-1]},
    {pelvis:[126,152], shoulder:[82,145], head:[58,138], wrist:[84,89],  elbowHint:[1,-0.2],
     ankle:[146,208], toe:[160,214], kneeHint:[0.4,-1]},
  ],
  /* Pull-up: the bar (wrist) is the fixed point; the body travels. Dead hang
     with a hollow line, then the chest rises TO the bar with a slight
     lay-back — chin clears bar height at the top, knees soft behind. */
  pullup: [
    {pelvis:[94,146], shoulder:[98,87],  head:[104,63], wrist:[96,30], elbowHint:[1,0],
     ankle:[102,238], toe:[112,243], kneeHint:[-1,0.2]},
    {pelvis:[92,119], shoulder:[101,60], head:[110,38], wrist:[96,30], elbowHint:[1,0],
     ankle:[100,208], toe:[110,214], kneeHint:[-1,0.2]},
    {pelvis:[90,103], shoulder:[104,44], head:[112,26], wrist:[96,30], elbowHint:[-1,0.3],
     ankle:[96,186],  toe:[106,192], kneeHint:[-1,0.2]},
  ],
  /* Pulldown: seated — pelvis and legs are furniture; the bar comes to the
     collarbone while the torso rocks back a few degrees, elbows down-back. */
  pulldown: [
    {pelvis:[104,145], shoulder:[102,89], head:[108,68], wrist:[96,34], elbowHint:[-0.3,0.6],
     knee:[132,158], ankle:[134,204], toe:[148,210]},
    {pelvis:[104,145], shoulder:[101,90], head:[107,66], wrist:[100,74], elbowHint:[-0.3,0.6],
     knee:[132,158], ankle:[134,204], toe:[148,210]},
    {pelvis:[104,145], shoulder:[99,90],  head:[106,64], wrist:[98,96], elbowHint:[-0.3,0.6],
     knee:[132,158], ankle:[134,204], toe:[148,210]},
  ],
  /* Dip: hands fixed on the bars, elbows travel BACK, and the torso tips
     forward as it sinks — upper arm reaches parallel at the bottom. */
  dip: [
    {pelvis:[103,133], shoulder:[100,76], head:[102,52], wrist:[98,128], elbowHint:[-1,0],
     knee:[118,166], ankle:[108,196], toe:[122,200]},
    {pelvis:[98,150],  shoulder:[102,94], head:[110,72], wrist:[98,128], elbowHint:[-1,0],
     knee:[118,172], ankle:[108,202], toe:[122,206]},
    {pelvis:[96,160],  shoulder:[104,102],head:[114,80], wrist:[98,128], elbowHint:[-1,0],
     knee:[118,178], ankle:[108,208], toe:[122,212]},
  ],
  /* Barbell row: the torso is a 42-degree table that does NOT move — the bar
     hangs plumb from the shoulder and pulls to the lower ribs, elbow driving
     back past the plane of the back. */
  row: [
    {pelvis:[75,125], shoulder:[115,80], head:[134,59], wrist:[113,136], elbowHint:[1,0],
     ...FEET, kneeHint:[1,0]},
    {pelvis:[75,125], shoulder:[115,80], head:[134,59], wrist:[110,118], elbowHint:[-1,0],
     ...FEET, kneeHint:[1,0]},
    {pelvis:[75,125], shoulder:[115,80], head:[134,59], wrist:[104,99],  elbowHint:[-1,-0.2],
     ...FEET, kneeHint:[1,0]},
  ],
  /* One-arm dumbbell row: same story braced on a bench. */
  dbrow: [
    {pelvis:[92,129], shoulder:[115,90], head:[128,74], wrist:[113,146], elbowHint:[1,0],
     ...FEET, kneeHint:[1,0]},
    {pelvis:[92,129], shoulder:[115,90], head:[128,74], wrist:[111,128], elbowHint:[-1,0],
     ...FEET, kneeHint:[1,0]},
    {pelvis:[92,129], shoulder:[115,90], head:[128,74], wrist:[108,112], elbowHint:[-1,-0.2],
     ...FEET, kneeHint:[1,0]},
  ],
};

if(import.meta.url === "file://" + process.argv[1]){
  for(const [name, keys] of Object.entries(SPECS)){
    console.log("== " + name);
    keys.forEach((S, i) => {
      const J = solveKey(S);
      console.log("  " + jline(J));
      console.log("  # " + report(name + "[" + i + "]", J));
    });
  }
}
