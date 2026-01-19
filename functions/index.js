const functions = require("firebase-functions");
const nodemailer = require("nodemailer");

const emailUser = functions.config().email?.user || "info@geodos.es";
const emailPass = functions.config().email?.pass || "APP_PASSWORD";

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: emailUser,
    pass: emailPass,
  },
});

exports.sendEmailOnContactForm = functions.firestore
  .document("contact_messages/{contactId}")
  .onCreate(async (snap) => {
    const data = snap.data() || {};
    const createdAt = data.createdAt?.toDate
      ? data.createdAt.toDate()
      : data.createdAt;
    const mailOptions = {
      from: `GEODOS <${emailUser}>`,
      to: ["info@geodos.es", "leoencero@gmail.com"],
      subject: `📩 Nuevo mensaje de ${data.name || "Contacto"}`,
      html: `
        <h2>Nuevo mensaje de contacto desde GEODOS</h2>
        <p><b>Nombre:</b> ${data.name || ""}</p>
        <p><b>Correo:</b> ${data.email || ""}</p>
        <p><b>Mensaje:</b><br>${data.message || ""}</p>
        <hr/>
        <p>📍 <b>Origen:</b> ${data.source || ""}</p>
        <p>🕒 <b>Fecha:</b> ${createdAt || ""}</p>
      `,
    };

    try {
      await transporter.sendMail(mailOptions);
      console.log(
        "✅ Correo enviado correctamente a info@geodos.es y leoencero@gmail.com"
      );
    } catch (error) {
      console.error("❌ Error enviando correo:", error);
    }
  });
