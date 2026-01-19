const functions = require("firebase-functions");
const nodemailer = require("nodemailer");

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: functions.config().email?.user || "admin@geodos.es",
    pass: functions.config().email?.pass || "APP_PASSWORD",
  },
});

exports.sendEmailOnContactForm = functions.firestore
  .document("contacts/{contactId}")
  .onCreate(async (snap) => {
    const data = snap.data();
    const mailOptions = {
      from: "GEODOS <admin@geodos.es>",
      to: "admin@geodos.es",
      subject: `📩 Nuevo formulario de contacto: ${data.name}`,
      text: `
        Nombre: ${data.name}
        Correo: ${data.email}
        Tipo: ${data.projectType}
        Mensaje: ${data.message}
      `,
    };
    await transporter.sendMail(mailOptions);
  });
