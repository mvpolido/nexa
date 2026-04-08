import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from "typeorm";

@Entity("users")
export class User {
    @PrimaryGeneratedColumn("uuid")
    id!: string; // Adicionada a !

    @Column({ unique: true })
    email!: string; // Adicionada a !

    @Column({ select: false })
    password!: string; // Adicionada a !

    @Column()
    name!: string; // Adicionada a !

    @CreateDateColumn()
    createdAt!: Date; // Adicionada a !

    @UpdateDateColumn()
    updatedAt!: Date; // Adicionada a !
}