import React, { useEffect, useState } from "react";
import { createRoot } from "react-dom/client";

function App() {
  const [students, setStudents] = useState([]);
  const [form, setForm] = useState({ name: "", email: "", age: 18 });

  const load = async () => setStudents(await fetch("/api/students").then(r => r.json()));
  useEffect(() => { load(); }, []);

  const submit = async e => {
    e.preventDefault();
    await fetch("/api/students", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(form) });
    setForm({ name: "", email: "", age: 18 }); load();
  };

  const remove = async id => { await fetch(`/api/students/${id}`, { method: "DELETE" }); load(); };

  return (
    <div style={{ maxWidth: 640, margin: "2rem auto", fontFamily: "system-ui" }}>
      <h1>Student Registration</h1>
      <form onSubmit={submit} style={{ display: "grid", gap: 8 }}>
        <input placeholder="Name"  value={form.name}  onChange={e=>setForm({...form, name:e.target.value})} required />
        <input placeholder="Email" value={form.email} onChange={e=>setForm({...form, email:e.target.value})} required />
        <input type="number" placeholder="Age" value={form.age} onChange={e=>setForm({...form, age:Number(e.target.value)})} required />
        <button>Add</button>
      </form>
      <h2 style={{marginTop:24}}>Students</h2>
      <ul>
        {students.map(s => (
          <li key={s.id}>
            {s.name} ({s.email}, {s.age}) <button onClick={()=>remove(s.id)}>Delete</button>
          </li>
        ))}
      </ul>
    </div>
  );
}

createRoot(document.getElementById("root")).render(<App/>);
