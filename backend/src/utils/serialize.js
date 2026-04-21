export const toClient = (doc) => {
  if (!doc) return null;
  const obj = doc.toObject ? doc.toObject({ versionKey: false }) : { ...doc };
  obj.id = obj._id ? obj._id.toString() : obj.id;
  delete obj._id;
  delete obj.__v;
  if (obj.password) delete obj.password;
  return obj;
};

export const listToClient = (docs) => docs.map((doc) => toClient(doc));
