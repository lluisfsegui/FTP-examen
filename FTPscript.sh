#!/bin/bash

# ==========================
# VARIABLES
# ==========================
PASS_1="12345678"
PASS_2="12345678"
PASS_3="12345678"
PASS_4="12345678"

USER_1="morgoth"
USER_2="sharku"
USER_3="eomer"
USER_4="frodo"  

HOME_1="/home/$USER_1"
HOME_2="/home/$USER_2"
HOME_3="/home/$USER_3"
HOME_4="/home/$USER_4"

DIR_ANONIM="/var/vinyamar/anonim"

# ==========================
# ACTUALIZAR SISTEMA
# ==========================
apt update -y

# ==========================
# INSTALAR VSFTPD
# ==========================
apt install vsftpd -y

# ==========================
# CREAR USUARIOS (si no existen)
# ==========================
for U in $USER_1 $USER_2 $USER_3 $USER_4; do
    id -u $U &>/dev/null || useradd -m -s /bin/bash $U
done

echo "$USER_1:$PASS_1" | chpasswd
echo "$USER_2:$PASS_2" | chpasswd
echo "$USER_3:$PASS_3" | chpasswd
echo "$USER_4:$PASS_4" | chpasswd

# ==========================
# DIRECTORIO ANONIM
# ==========================
mkdir -p $DIR_ANONIM
chmod 775 $DIR_ANONIM

# Els dos primers poden llegir i escriure
chown $USER_1:$USER_1 $DIR_ANONIM
setfacl -m u:$USER_2:rwx $DIR_ANONIM

# ==========================
# PERMISOS USUARIOS ENGABIADOS
# ==========================
for HOME in $HOME_1 $HOME_2 $HOME_3; do
    chown root:root $HOME
    chmod 755 $HOME
done

# ==========================
# CONFIGURAR VSFTPD
# ==========================
cp /etc/vsftpd.conf /etc/vsftpd.conf.bak

cat <<EOF > /etc/vsftpd.conf
listen=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022

# Engabiar per defecte
chroot_local_user=YES
allow_writeable_chroot=YES

# Usuari NO engabiat
chroot_list_enable=YES
chroot_list_file=/etc/vsftpd.chroot_list

pasv_enable=YES
pasv_min_port=10000
pasv_max_port=10100

user_sub_token=\$USER
local_root=/home/\$USER
EOF

# ==========================
# CONFIGURAR LISTA DE USUARIOS NO ENGABIADOS
# ==========================
echo "$USER_4" > /etc/vsftpd.chroot_list

# ==========================
# REINICIAR SERVICIO
# ==========================
systemctl restart vsftpd
systemctl enable vsftpd

# ==========================
# MENSAJE FINAL
# ==========================
echo "FTP configurado correctamente"
echo "Usuarios engabiados: $USER_1, $USER_2, $USER_3"
echo "Usuario NO engabiado: $USER_4"
echo "Usuarios con acceso RW a $DIR_ANONIM: $USER_1, $USER_2"
